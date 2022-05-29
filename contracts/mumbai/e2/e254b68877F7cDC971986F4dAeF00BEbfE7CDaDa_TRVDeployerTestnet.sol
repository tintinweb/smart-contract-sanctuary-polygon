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

    accessControl = 0xFf8434fDA67fb91BF315D3a78A1Af9f001495C88;

    cAState = 0xA78d7ad2E23BB3CF4645DFdaA8a661397D8c7B0B;
    cFState = 0x9410a2CC8b677FFdFA341C5A98Ef35235e99Eae4;
    tournamentState = 0x75Da8e3e4330257dA2e24e0252d33DF2BE092A8e;

    championUtils = 0x0310Ba2f47b39cbC044B9b7F11b3EA01611347eB;
    bloodingService = 0x47e01eD803bc107D72515756358383fd60aFB429;
    bloodbathService = 0x7Fb6232ac02C3be3d93cD8bb584974C35Ca6500B;
    bloodEloService = 0xFF4eB4dE6D6B50Cdd13297e576466B7445c2dfEb;
    soloService = 0xad211597751D305D0bd64AB34b1837FE2977293E;

    tournamentRoute = 0x54af5f1538b936DAB41b02df82Cc3cf5ac15F7B8;
  }

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function setContracts(
    address _contract1,
    address _contract2,
    address _contract3,
    address _contract4,
    address _contract5,
    address _contract6,
    address _contract7,
    address _contract8,
    address _contract9,
    address _contract10
  ) external onlyOwner {
    accessControl = _contract1;

    cAState = _contract2;
    cFState = _contract3;
    tournamentState = _contract4;
    championUtils = _contract5;
    bloodingService = _contract6;
    bloodbathService = _contract7;
    bloodEloService = _contract8;
    soloService = _contract9;
    tournamentRoute = _contract10;
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