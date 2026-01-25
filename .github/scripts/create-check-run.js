const fs = require('fs');

module.exports = async ({ github, context, planOutputFile, exitCode }) => {
  // Read plan output from file
  const planOutput = fs.readFileSync(planOutputFile, 'utf8');

  // Parse the plan output
  const addMatch = planOutput.match(/(\d+) to add/);
  const changeMatch = planOutput.match(/(\d+) to change/);
  const destroyMatch = planOutput.match(/(\d+) to destroy/);
  const errorMatch = planOutput.match(/Error:/);
  
  const toAdd = addMatch ? parseInt(addMatch[1]) : 0;
  const toChange = changeMatch ? parseInt(changeMatch[1]) : 0;
  const toDestroy = destroyMatch ? parseInt(destroyMatch[1]) : 0;
  const hasError = errorMatch !== null || exitCode === 1;
  
  // Determine conclusion based on exit code
  // 0 = success (no changes), 1 = error, 2 = success (changes present)
  let conclusion = 'success';
  let title = '✅ Terraform Plan: No Changes';
  
  if (hasError) {
    conclusion = 'failure';
    title = '❌ Terraform Plan Failed';
  } else if (toAdd > 0 || toChange > 0 || toDestroy > 0) {
    conclusion = 'success';
    title = `📋 Terraform Plan: ${toAdd} to add, ${toChange} to change, ${toDestroy} to destroy`;
    
    // Mark as action_required if destroying resources
    if (toDestroy > 0) {
      conclusion = 'action_required';
      title = `⚠️ Terraform Plan: ${toDestroy} resource(s) will be DESTROYED`;
    }
  }
  
  // Build summary with emoji indicators
  let summary = '## Terraform Plan Summary\n\n';
  
  if (hasError) {
    summary += '### ❌ Plan Failed\n\n';
    summary += 'The Terraform plan encountered an error. Please review the details below.\n\n';
  } else {
    summary += '| Change Type | Count |\n';
    summary += '|-------------|-------|\n';
    summary += `| ➕ Add | ${toAdd} |\n`;
    summary += `| 🔄 Change | ${toChange} |\n`;
    summary += `| ➖ Destroy | ${toDestroy} |\n\n`;
    
    if (toDestroy > 0) {
      summary += '> ⚠️ **Warning:** This plan includes resource destruction. Please review carefully!\n\n';
    }
    
    if (toAdd === 0 && toChange === 0 && toDestroy === 0) {
      summary += '✨ **No infrastructure changes detected.**\n\n';
    }
  }
  
  // Extract resource changes for detailed view
  const resourceChanges = [];
  const resourcePattern = /# ([\w\.\[\]"_-]+) will be (created|updated|destroyed|replaced)/g;
  let match;
  while ((match = resourcePattern.exec(planOutput)) !== null) {
    const action = match[2];
    const emoji = {
      'created': '➕',
      'updated': '🔄', 
      'destroyed': '➖',
      'replaced': '🔃'
    }[action] || '•';
    resourceChanges.push(`${emoji} \`${match[1]}\` will be ${action}`);
  }
  
  if (resourceChanges.length > 0) {
    summary += '### Resources Affected\n\n';
    summary += resourceChanges.join('\n') + '\n\n';
  }
  
  // Truncate plan output for text field (max 65535 chars)
  let planText = '```hcl\n' + planOutput + '\n```';
  if (planText.length > 65000) {
    planText = '```hcl\n' + planOutput.substring(0, 64000) + '\n...(truncated)\n```';
  }
  
  // Build annotations for errors/warnings
  const annotations = [];
  
  // Find error lines and create annotations
  const errorLines = planOutput.split('\n');
  for (let i = 0; i < errorLines.length; i++) {
    const line = errorLines[i];
    
    // Match Terraform error format: on filename.tf line X
    const errorFileMatch = line.match(/on ([\w\-\.\/]+\.tf) line (\d+)/);
    if (errorFileMatch) {
      const errorMsgLines = [];
      for (let j = i; j < Math.min(i + 5, errorLines.length); j++) {
        if (errorLines[j].trim()) {
          errorMsgLines.push(errorLines[j]);
        }
      }
      annotations.push({
        path: errorFileMatch[1],
        start_line: parseInt(errorFileMatch[2]),
        end_line: parseInt(errorFileMatch[2]),
        annotation_level: 'failure',
        message: errorMsgLines.join('\n'),
        title: 'Terraform Error'
      });
    }
    
    // Match deprecation warnings
    if (line.includes('Warning:') || line.includes('deprecated')) {
      const warnFileMatch = line.match(/([\w\-\.\/]+\.tf)/);
      if (warnFileMatch && annotations.length < 50) {
        annotations.push({
          path: warnFileMatch[1],
          start_line: 1,
          end_line: 1,
          annotation_level: 'warning',
          message: line,
          title: 'Terraform Warning'
        });
      }
    }
  }
  
  // Create the check run
  await github.rest.checks.create({
    owner: context.repo.owner,
    repo: context.repo.repo,
    name: 'Terraform Plan',
    head_sha: context.sha,
    status: 'completed',
    conclusion: conclusion,
    output: {
      title: title,
      summary: summary,
      text: planText,
      annotations: annotations.slice(0, 50) // GitHub limits to 50 annotations
    },
    actions: toDestroy > 0 ? [
      {
        label: 'Approve Destroy',
        description: 'Acknowledge destruction of resources',
        identifier: 'approve_destroy'
      }
    ] : []
  });
  
  // Also post as PR comment for visibility
  const prNumber = context.payload.pull_request?.number;
  if (prNumber) {
    const commentBody = `## 🏗️ Terraform Plan Results\n\n${summary}\n<details>\n<summary>Full Plan Output</summary>\n\n\`\`\`hcl\n${planOutput.substring(0, 60000)}\n\`\`\`\n</details>`;
    
    // Find existing comment to update
    const comments = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: prNumber
    });
    
    const botComment = comments.data.find(c => 
      c.user.type === 'Bot' && c.body.includes('Terraform Plan Results')
    );
    
    if (botComment) {
      await github.rest.issues.updateComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        comment_id: botComment.id,
        body: commentBody
      });
    } else {
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: prNumber,
        body: commentBody
      });
    }
  }
};
