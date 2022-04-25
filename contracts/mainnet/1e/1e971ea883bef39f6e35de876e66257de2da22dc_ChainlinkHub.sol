/**
 *Submitted for verification at polygonscan.com on 2022-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOracle {
    function latestAnswer() external view returns(uint256);
    function decimals() external view returns(uint256);
    function description() external view returns(string memory);
}

contract ChainlinkHub {

    mapping(uint256 => address) public oracles; // chainlink oracles addresses
    uint256 public oracleNextIndex = 1; // it starts from 1 because the 0 index is v-usd
    address public governance;

    event OracleAdded(address oracle);
    event GovernanceChanged(address oldG, address newG);

    constructor() {
        governance = msg.sender;
    }

    /// @notice add new oracles to the hub
	/// @param _oracles oracle addresses
    function addOracles(address[] memory _oracles) external {
        require(msg.sender == governance, "!gov");
        for (uint256 i = 0; i < _oracles.length; i++) {
            _addOracle(_oracles[i]);
        }
    }

    /// @notice add new oracle to the hub
	/// @param _oracle oracle address
    function addOracle(address _oracle) external {
        require(msg.sender == governance, "!gov");
        _addOracle(_oracle);
    }

    /// @notice internal function to add a new oracle to the hub
	/// @param _oracle oracle address
    function _addOracle(address _oracle) internal {
        require(_oracle != address(0));
        oracles[oracleNextIndex] = _oracle;
        oracleNextIndex++;
        emit OracleAdded(_oracle);
    }

    /// @notice get the last USD price for the asset
	/// @param _assetIndex index of the asset
    function getLastUSDPrice(uint256 _assetIndex) external view returns(uint256) {
        address oracle = oracles[_assetIndex];
        return IOracle(oracle).latestAnswer() * (1e18 / 10**IOracle(oracle).decimals());
    }

    /// @notice add new oracle to the hub
	/// @param _assetIndex oracle address
    /// @param _amount asset amount
    function getUSDForAmount(uint256 _assetIndex, uint256 _amount) external view returns(uint256) {
        address oracle = oracles[_assetIndex];
        uint256 usdValue = IOracle(oracle).latestAnswer();
        return usdValue * _amount / 10**IOracle(oracle).decimals();
    }

    /// @notice get the asset description
	/// @param _assetIndex oracle address
    function assetDescription(uint256 _assetIndex) external view returns(string memory) {
        address oracle = oracles[_assetIndex];
        return IOracle(oracle).description();
    }

    /// @notice set the governance
	/// @param _governance governance address
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!gov");
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }
}