// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../interfaces/chainlink/AggregatorV3Interface.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Helpers} from "../utils/Helpers.sol";

abstract contract OracleRouterBase is IOracle {
    uint256 constant MIN_DRIFT = uint256(70000000);
    uint256 constant MAX_DRIFT = uint256(130000000);

    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     * @return address address of the price feed for the asset
     */
    function feed(address asset) internal view virtual returns (address);

    /**
     * @notice Returns the total price in 8 digit USD for a given asset.
     * @param asset address of the asset
     * @return uint256 USD price of 1 of the asset, in 8 decimal fixed
     */
    function price(address asset) external view override returns (uint256) {
        address _feed = feed(asset);
        require(_feed != address(0), "Asset not available");
        (, int256 _iprice, , , ) = AggregatorV3Interface(_feed)
            .latestRoundData();
        uint256 _price = uint256(_iprice);
        if (isStablecoin(asset)) {
            require(_price <= MAX_DRIFT, "Oracle: Price exceeds max");
            require(_price >= MIN_DRIFT, "Oracle: Price under min");
        }
        return uint256(_price);
    }

    function isStablecoin(address _asset) internal view returns (bool) {
        string memory symbol = Helpers.getSymbol(_asset);
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return
            // symbolHash == keccak256(abi.encodePacked("DAI")) ||
            symbolHash == keccak256(abi.encodePacked("DAI")) ||
            symbolHash == keccak256(abi.encodePacked("USDC")) ||
            symbolHash == keccak256(abi.encodePacked("USDT"));
    }
}

contract OracleRouterPolygon is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal pure override returns (address) {

        if (asset == address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063)) {
            // Chainlink: DAI/USD
            return address(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D);
        } else if (
            asset == address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
        ) {
            // Chainlink: USDC/USD
            return address(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);
        } else if (
            asset == address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F)
        ) {
            // Chainlink: USDT/USD
            return address(0x0A6513e40db6EB1b165753AD52E80663aeA50545);
        } else if (
            asset == address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B)
        ) {
            // Chainlink: AAVE/USD
            return address(0x72484B12719E23115761D5DA1646945632979bB6);
        } else {
            revert("Asset not available");
        }
    }
}

contract OracleRouterBsc is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal pure override returns (address) {
        if (asset == address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)){
            //ChainLink : BUSD/USD
            return address(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);
        }
        else if (asset == address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)) {
            // Chainlink: USDC/USD
            return address(0x51597f405303C4377E36123cBc172b13269EA163);
        } else if (
            asset == address(0x55d398326f99059fF775485246999027B3197955)
        ) {
            // Chainlink: USDT/USD
            return address(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);
        } else if (
            asset == address(0x52CE071Bd9b1C4B00A0b92D298c512478CaD67e8)
        ) {
            // Chainlink: COMP/USD
            return address(0x0Db8945f9aEf5651fa5bd52314C5aAe78DfDe540);
        } else if (
            asset == address(0xfb6115445Bff7b52FeB98650C87f44907E58f802)
        ) {
            // Chainlink: AAVE/USD
            return address(0xA8357BF572460fC40f4B0aCacbB2a6A61c89f475);
        } else {
            revert("Asset not available");
        }
    }
}

contract OracleRouterMumbai is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal pure override returns (address) {
        if (asset == address(0x3813e82e6f7098b9583FC0F33a962D02018B6803)){
            //ChainLink : USDT/USD
            return address(0x92C09849638959196E976289418e5973CC96d645);
        }
        else if (asset == address(0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747)){
            //ChainLink : USDT/USD
            return address(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);
        }
         else {
            revert("Asset not available");
        }
    }
}

contract OracleRouterDev is OracleRouterBase {
    mapping(address => address) public assetToFeed;

    function setFeed(address _asset, address _feed) external {
        assetToFeed[_asset] = _feed;
    }
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal view override returns (address) {
        return assetToFeed[asset];
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @dev returns the asset price in USD, 8 decimal digits.
     */
    function price(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { IBasicToken } from "../interfaces/IBasicToken.sol";

library Helpers {
    /**
     * @notice Fetch the `symbol()` from an ERC20 token
     * @dev Grabs the `symbol()` from a contract
     * @param _token Address of the ERC20 token
     * @return string Symbol of the ERC20 token
     */
    function getSymbol(address _token) internal view returns (string memory) {
        string memory symbol = IBasicToken(_token).symbol();
        return symbol;
    }

    /**
     * @notice Fetch the `decimals()` from an ERC20 token
     * @dev Grabs the `decimals()` from a contract and fails if
     *      the decimal value does not live within a certain range
     * @param _token Address of the ERC20 token
     * @return uint256 Decimals of the ERC20 token
     */
    function getDecimals(address _token) internal view returns (uint256) {
        uint256 decimals = IBasicToken(_token).decimals();
        require(
            decimals >= 4 && decimals <= 18,
            "Token must have sufficient decimal places"
        );

        return decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}