using '../../../../iac/ptn/graph/group/main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../config/main.config.json')

var projectCCoE = 'projects-CCoE'
var serviceShortCCoE = '${config.prefix}-ccoe-${config.uniqueId}'

var projectPortugal = 'projects-Portugal'
var serviceShortPortugal = '${config.prefix}-portugal-${config.uniqueId}'

var projectService = 'shared-Services'
var serviceShortService = '${config.prefix}-services-${config.uniqueId}'

var projectCollab = 'shared-Collaboration'
var serviceShortCollab = '${config.prefix}-collaboration-${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

param securityGroups = [
  // CCoE Groups
  {
    displayName: 'SG ${toUpper(config.prefix)} CCoE - Administrators'
    uniqueName: '${serviceShortCCoE}-admins'
    mailNickname: '${serviceShortCCoE}-admins'
    description: 'Administrators group for ${projectCCoE} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} CCoE - Developers'
    uniqueName: '${serviceShortCCoE}-devs'
    mailNickname: '${serviceShortCCoE}-devs'
    description: 'Developers group for ${projectCCoE} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} CCoE - Stakeholders'
    uniqueName: '${serviceShortCCoE}-stakes'
    mailNickname: '${serviceShortCCoE}-stakes'
    description: 'Stakeholders group for ${projectCCoE} project.'
  }
  // Portugal Groups
  {
    displayName: 'SG ${toUpper(config.prefix)} Portugal - Administrators'
    uniqueName: '${serviceShortPortugal}-admins'
    mailNickname: '${serviceShortPortugal}-admins'
    description: 'Administrators group for ${projectPortugal} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Portugal - Developers'
    uniqueName: '${serviceShortPortugal}-devs'
    mailNickname: '${serviceShortPortugal}-devs'
    description: 'Developers group for ${projectPortugal} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Portugal - Stakeholders'
    uniqueName: '${serviceShortPortugal}-stakes'
    mailNickname: '${serviceShortPortugal}-stakes'
    description: 'Stakeholders group for ${projectPortugal} project.'
  }
  // Services groups
  {
    displayName: 'SG ${toUpper(config.prefix)} Services - Administrators'
    uniqueName: '${serviceShortService}-admins'
    mailNickname: '${serviceShortService}-admins'
    description: 'Administrators group for ${projectService} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Services - Developers'
    uniqueName: '${serviceShortService}-devs'
    mailNickname: '${serviceShortService}-devs'
    description: 'Developers group for ${projectService} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Services - Stakeholders'
    uniqueName: '${serviceShortService}-stakes'
    mailNickname: '${serviceShortService}-stakes'
    description: 'Stakeholders group for ${projectService} project.'
  }
  // Collaboration groups
  {
    displayName: 'SG ${toUpper(config.prefix)} Collaboration - Administrators'
    uniqueName: '${serviceShortCollab}-admins'
    mailNickname: '${serviceShortCollab}-admins'
    description: 'Administrators group for ${projectCollab} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Collaboration - Developers'
    uniqueName: '${serviceShortCollab}-devs'
    mailNickname: '${serviceShortCollab}-devs'
    description: 'Developers group for ${projectCollab} project.'
  }
  {
    displayName: 'SG ${toUpper(config.prefix)} Collaboration - Stakeholders'
    uniqueName: '${serviceShortCollab}-stakes'
    mailNickname: '${serviceShortCollab}-stakes'
    description: 'Stakeholders group for ${projectCollab} project.'
  }
]
