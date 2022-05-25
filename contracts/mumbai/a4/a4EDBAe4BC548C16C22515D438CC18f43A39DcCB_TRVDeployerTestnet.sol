// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TRVDeployerTestnet {
  address public owner;

  address public accessControl;

  address public cAState;
  address public cFState;
  address public tournamentState;

  address public championUtils;

  address public bloodingService;
  address public bloodbathService;
  address public bloodEloService;

  address public soloService;

  address public tournamentRoute;

  constructor() {
    owner = msg.sender;

    accessControl = 0x13a07Af06f7730f0B236b944661Bac7526601123;

    cAState = 0xb09746073e9491BefAD1d2B485E424e08B3fee04;
    cFState = 0xe78eEe090C211dc84b73EB95557Ff0863B3aF1Ac;
    tournamentState = 0x3FE22D949896092DF60b1B4B3455Dee70E65079B;

    championUtils = 0x3a23fE2Ed57781A1A736813bC63928C25338b43a;
    bloodingService = 0xd270985187B91d6677aF750fC572da71b7514124;
    bloodbathService = 0x9B6cCdE986E5F1C18D92057CF5BA19610ba33D5E;
    bloodEloService = 0x572CB947B95e87B4db14e78f1a2D417058254C3b;
    soloService = 0x091d0CfA8a9518eC3D3a34b920f351F64C071121;

    tournamentRoute = 0x5F207AD5fEA49A14b3cc32d1Ba4b0a2E869F8038;
  }

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function init() external onlyOwner {
    IAll(accessControl).grantMaster(address(this), cAState);
    IAll(accessControl).grantMaster(address(this), cFState);
    IAll(accessControl).grantMaster(address(this), tournamentState);

    IAll(accessControl).grantMaster(address(this), championUtils);
    IAll(accessControl).grantMaster(address(this), bloodingService);
    IAll(accessControl).grantMaster(address(this), bloodbathService);
    IAll(accessControl).grantMaster(address(this), bloodEloService);
    IAll(accessControl).grantMaster(address(this), soloService);

    IAll(accessControl).grantMaster(address(this), tournamentRoute);
  }

  function setup() external onlyOwner {
    IAll(accessControl).setAccessControlProvider(accessControl);
    IAll(cAState).setAccessControlProvider(accessControl);
    IAll(cFState).setAccessControlProvider(accessControl);
    IAll(tournamentState).setAccessControlProvider(accessControl);
    IAll(championUtils).setAccessControlProvider(accessControl);
    IAll(bloodingService).setAccessControlProvider(accessControl);
    IAll(bloodbathService).setAccessControlProvider(accessControl);
    IAll(bloodEloService).setAccessControlProvider(accessControl);
    IAll(soloService).setAccessControlProvider(accessControl);
    IAll(tournamentRoute).setAccessControlProvider(accessControl);
  }

  function bindingService() external onlyOwner {
    bindingRoleForService(bloodingService);
    bindingRoleForService(bloodbathService);
    bindingRoleForService(bloodEloService);
    bindingRoleForService(soloService);
  }

  function bindingRoleForService(address _service) internal {
    IAll(accessControl).grantMaster(_service, cAState);
    IAll(accessControl).grantMaster(_service, cFState);
    IAll(accessControl).grantMaster(_service, tournamentState);

    IAll(_service).bindChampionAttributesState(cAState);
    IAll(_service).bindChampionFightingState(cFState);
    IAll(_service).bindTournamentState(tournamentState);
    IAll(_service).bindChampionUtils(championUtils);
  }

  function bindingRoleForRoute() external onlyOwner {
    IAll(accessControl).grantMaster(tournamentRoute, bloodingService);
    IAll(accessControl).grantMaster(tournamentRoute, bloodbathService);
    IAll(accessControl).grantMaster(tournamentRoute, bloodEloService);
    IAll(accessControl).grantMaster(tournamentRoute, soloService);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(tournamentRoute).bindService(0, soloService);
    IAll(tournamentRoute).bindService(1, bloodingService);
    IAll(tournamentRoute).bindService(2, bloodbathService);
    IAll(tournamentRoute).bindService(3, bloodEloService);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;
  function grantMaster(address, address) external;
  function bindChampionAttributesState(address) external;
  function bindChampionFightingState(address) external;
  function bindTournamentState(address) external;
  function bindChampionUtils(address) external;
  function bindService(uint64, address) external;
}