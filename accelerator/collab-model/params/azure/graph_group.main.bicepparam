using '../../../../iac/ptn/graph/group/main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../config/main.config.json')

var serviceShort = '${config.prefix}-${toLower(config.service)}-${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

param securityGroups = [
  {
    displayName: 'SG ${toUpper(config.prefix)} ${config.service} - Administrators'
    uniqueName: '${serviceShort}-admins'
    mailNickname: '${serviceShort}-admins'
    description: 'Administrators group for ${serviceShort} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} ${config.service} - Developers'
    uniqueName: '${serviceShort}-devs'
    mailNickname: '${serviceShort}-devs'
    description: 'Developers group for ${serviceShort} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} ${config.service} - Stakeholders'
    uniqueName: '${serviceShort}-stakes'
    mailNickname: '${serviceShort}-stakes'
    description: 'Stakeholders group for ${serviceShort} project.'
  }
]
