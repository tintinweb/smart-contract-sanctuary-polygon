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

    accessControl = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

    cAState = 0x5A06c52A8B4eF58173A91A8fFE342A09AaF4Fc9D;
    cFState = 0xCF25D328550Bd4e2A214e57331b04d80F0C088Ca;
    tournamentState = 0x913B34CB9597f899EEE159a0b5564e4cC2958330;

    championUtils = 0x2017A7591b8CC757a00B4011Db0A901a5aA890ee;
    bloodingService = 0x43ABFeB4656c83247CDC5FaA74865D9110a9eB2D;
    bloodbathService = 0x19b6cac7f40a23F5c49d70fd06284D48d6F700FE;
    bloodEloService = 0x2e987eA483f67Ccb04696E59AA8dD427e04FC5f3;
    soloService = 0x8e5Ea2D61cF1Bb1d32b7327d32E3B18549AF4e87;

    tournamentRoute = 0x570F2d96a114F272Fc461440B4C3b08dC7007F5E;
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