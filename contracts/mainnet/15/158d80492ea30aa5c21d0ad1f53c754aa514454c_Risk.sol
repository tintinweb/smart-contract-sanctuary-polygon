// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Risk {
    struct Data {
        mapping(string => RiskItem) riskItems;
        mapping(string => bool) ratingFlags;
    }

    struct RiskItem {
        uint256 interestRate;
        uint256 advanceRate;
    }
    
    function set(Data storage self, string memory key, uint256 interestRate, uint256 advanceRate) external {
        self.riskItems[key] = RiskItem(interestRate, advanceRate);
        self.ratingFlags[key] = true;
    }

    function getInterestRate(Data storage self, string memory key) external view returns (uint256) {
        return self.riskItems[key].interestRate;
    }

    function getAdvanceRate(Data storage self, string memory key) external view returns (uint256) {
        return self.riskItems[key].advanceRate;
    }

    function remove(Data storage self, string memory key) external {
        delete self.ratingFlags[key];
        delete self.riskItems[key];
    }
}