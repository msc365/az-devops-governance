using '../main.bicep'

var config = loadJsonContent('../../../../../src/cfg/main.config.json')

var resourceName = '${config.prefix}-prj${config.uniqueId}'

// Security group unique names
var stakeholderGroupUniqueName = 'sg-${resourceName}-stakeholders'
var developerGroupUniqueName = 'sg-${resourceName}-developers'
var administratorGroupUniqueName = 'sg-${resourceName}-administrators'

param groups = [
  {
    displayName: 'SG ${resourceName} Administrators'
    uniqueName: administratorGroupUniqueName
    mailNickname: administratorGroupUniqueName
  }
  {
    displayName: 'SG ${resourceName} Developers'
    uniqueName: developerGroupUniqueName
    mailNickname: developerGroupUniqueName
  }
  {
    displayName: 'SG ${resourceName} Stakeholders'
    uniqueName: stakeholderGroupUniqueName
    mailNickname: stakeholderGroupUniqueName
  }
]
