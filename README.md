# Update Repository Custom Property Action

This GitHub Action sets a custom property for a specified repository using the GitHub API. It returns a result indicating success or failure and an error message if the operation fails.

## Features
- Updates a custom property (e.g., `requires-build-check`) to a specified value (e.g., `Enabled`) for a repository via the GitHub API.
- Outputs a result (`success` or `failure`) and an error message for easy integration into workflows.
- Requires a GitHub token with `admin:org` or `repo` scope with admin permissions for setting custom properties.

## Inputs
| Name             | Description                                      | Required | Default              |
|------------------|--------------------------------------------------|----------|---------------------|
| `repo-name`      | The name of the repository to set the custom property for. | Yes      | N/A                 |
| `owner`          | The owner of the repository (user or organization). | Yes      | N/A                 |
| `token`          | GitHub token with repository admin access.       | Yes      | N/A                 |
| `property-name`  | The name of the custom property to set.          | Yes      | N/A |
| `property-value` | The value to set for the custom property.        | Yes      | N/A             |

## Outputs
| Name           | Description                                           |
|----------------|-------------------------------------------------------|
| `result`       | Result of the custom property update (`success` for HTTP 204, `failure` otherwise). |
| `error-message`| Error message if the custom property update fails.     |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/set-custom-property.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`), or the local path if stored in the same repository.

3. **Example Workflow**:
   ```yaml
   name: Set Repository Custom Property
   on:
     push:
       branches:
         - main
   jobs:
     set-property:
       runs-on: ubuntu-latest
       steps:
         - name: Set Custom Property
           id: set
           uses: la-actions/update-repo-custom-property@v1
           with:
             repo-name: 'my-repo'
             owner: ${{ github.repository_owner }}
             token: ${{ secrets.GITHUB_TOKEN }}
             property-name: 'requires-build-check'
             property-value: 'Enabled'
         - name: Check Result
           run: |
             if [[ "${{ steps.set.outputs.result }}" == "success" ]]; then
               echo "Custom property set successfully."
             else
               echo "${{ steps.set.outputs.error-message }}"
               exit 1
             fi
