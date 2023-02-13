// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TradingCompetitionApplication {
  address public admin;
  mapping(address => bool) public applicants; // not a struct to support guild custom query capabilities
  mapping(address => string) public referrer;

  modifier onlyAdmin() {
    require(msg.sender == admin, "not admin");
    _;
  }

  constructor() {
    admin = msg.sender;
  }

  /**
   * @dev applyToTrade set application for address to referrer
   * @dev referrer - the referrer that brought the candidate to the games
   */
  function applyToTrade(string memory referrerParam) external {
    applicants[msg.sender] = true;
    referrer[msg.sender] = referrerParam;
  }

  /**
   * @dev applyToTradeMultiForRefferer set applications for address true
   * @dev manualApplicants list of applicants to manually add
   * @dev referrer - single referrer to platform
   */
  function applyToTradeMultiForRefferer(address[] calldata manualApplicants, string memory referrerParam) external onlyAdmin {
    for (uint256 i = 0; i < manualApplicants.length; i++) {
      applicants[manualApplicants[i]] = true;
      referrer[manualApplicants[i]] = referrerParam;
    }
  }

  /**
   * @dev set admin set application for address true
   * @dev newAdmin
   */
  function setAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
  }
}