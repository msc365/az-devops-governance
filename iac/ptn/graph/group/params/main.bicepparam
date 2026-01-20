using '../main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../../../../src/cfg/main.config.json')

var serviceShort = '${config.prefix}-prj${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

param securityGroups = [
  {
    displayName: 'SG ${serviceShort} Administrators'
    uniqueName: '${serviceShort}-admins'
    mailNickname: '${serviceShort}-admins'
    description: 'Administrators group for ${serviceShort} project.'
  }
  {
    displayName: 'SG ${serviceShort} Developers'
    uniqueName: '${serviceShort}-devs'
    mailNickname: '${serviceShort}-devs'
    description: 'Developers group for ${serviceShort} project.'
  }
  {
    displayName: 'SG ${serviceShort} Stakeholders'
    uniqueName: '${serviceShort}-stakes'
    mailNickname: '${serviceShort}-stakes'
    description: 'Stakeholders group for ${serviceShort} project.'
  }
]
