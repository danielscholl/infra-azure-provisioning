## Infrastructure Submissions:
-------------------------------------
* [YES/NO] Have you added an explanation of what your changes do and why you'd like us to include them?
* [YES/NO] I have updated the documentation accordingly.
* [YES/NO/NA] I have added tests to cover my changes.
* [YES/NO/NA] All new and existing tests passed.
* [YES/NO/NA] I have formatted the terraform code.  _(`terraform fmt -recursive && go fmt ./...`)_

## Current Behavior or Linked Issues
-------------------------------------
<!-- Please describe the current behavior that you are modifying, or link to a relevant issue. -->


## Does this introduce a breaking change?
-------------------------------------
- [YES/NO]

<!-- If this introduces a breaking change, please describe the impact and migration path for existing applications below. -->

## MR Guildelines
- [ ] Temporary changes should be made with overrides and reverted. No changes are to be made to the Azure Portal. 
- [ ] Code in GLab, Dev and Master should be in synch as this is what customers use. 
- [ ]  Pre-Merge pipeline should be run before merging. 
- [ ] MRs should output the changes of TF Plan. 
- [ ] Use existing modules for creation of resources. 
- [ ]  Any new variables should not break the existing code. (Don’t use library variables and use locals) 

## Other information
-------------------------------------
<!-- Any other information that is important to this PR such as screenshots of how the component looks before and after the change. -->
