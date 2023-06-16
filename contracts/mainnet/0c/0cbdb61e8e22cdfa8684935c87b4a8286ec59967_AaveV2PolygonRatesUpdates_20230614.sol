// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity ^0.8.0;

import 'aave-helpers/v2-config-engine/AaveV2PayloadPolygon.sol';
import {AaveV2Polygon, AaveV2PolygonAssets, ILendingPoolConfigurator} from 'aave-address-book/AaveV2Polygon.sol';

/**
 * @dev Smart contract for a mock rates update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV2PolygonRatesUpdates_20230614 is AaveV2PayloadPolygon {

  function _postExecute() internal override {
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.DAI_UNDERLYING, 21_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.USDC_UNDERLYING, 23_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.USDT_UNDERLYING, 22_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.WBTC_UNDERLYING, 55_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.WETH_UNDERLYING, 45_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.WMATIC_UNDERLYING, 41_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.BAL_UNDERLYING, 32_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.CRV_UNDERLYING, 38_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.GHST_UNDERLYING, 60_00);
    ILendingPoolConfigurator(AaveV2Polygon.POOL_CONFIGURATOR).setReserveFactor(AaveV2PolygonAssets.LINK_UNDERLYING, 50_00);
  }

  function rateStrategiesUpdates()
    public
    pure
    override
    returns (IEngine.RateStrategyUpdate[] memory)
  {
    IEngine.RateStrategyUpdate[] memory rateStrategy = new IEngine.RateStrategyUpdate[](10);

    rateStrategy[0] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.DAI_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(71_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(105_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(105_00)
      })
    });

    rateStrategy[1] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.USDC_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(77_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(134_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(134_00)
      })
    });

    rateStrategy[2] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.USDT_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(52_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(236_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(236_00)
      })
    });

    rateStrategy[3] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.WBTC_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(37_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(536_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(536_00)
      })
    });

    rateStrategy[4] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.WETH_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(40_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(167_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(167_00)
      })
    });

    rateStrategy[5] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.WMATIC_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(48_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(440_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(440_00)
      })
    });

    rateStrategy[6] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.BAL_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(65_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(236_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(236_00)
      })
    });

    rateStrategy[7] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.CRV_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(25_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(392_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(392_00)
      })
    });

    rateStrategy[8] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.GHST_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(23_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(413_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(413_00)
      })
    });

    rateStrategy[9] = IEngine.RateStrategyUpdate({
      asset: AaveV2PolygonAssets.LINK_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(25_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: EngineFlags.KEEP_CURRENT,
        variableRateSlope2: _bpsToRay(402_00),
        stableRateSlope1: EngineFlags.KEEP_CURRENT,
        stableRateSlope2: _bpsToRay(402_00)
      })
    });

    return rateStrategy;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import './AaveV2PayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v2 rates update on Avalanche.
 * @author BGD Labs
 */
// TODO: Add rates factory address after deploying
abstract contract AaveV2PayloadPolygon is AaveV2PayloadBase(IEngine(AaveV2Polygon.LISTING_ENGINE)) {

}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';
import {ICollector} from './common/ICollector.sol';

library AaveV2Polygon {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);

  ILendingPool internal constant POOL = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x26db2B833021583566323E3b8985999981b9F1F3);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);

  ILendingRateOracle internal constant LENDING_RATE_ORACLE =
    ILendingRateOracle(0x17F73aEaD876CC4059089ff815EDA37052960dFB);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

  address internal constant POOL_ADMIN = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant EMERGENCY_ADMIN = 0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58;

  ICollector internal constant COLLECTOR = ICollector(0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x357D51124f59836DeD84c8a1730D72B749d8BC23;

  address internal constant EMISSION_MANAGER = 0x2bB25175d9B0F8965780209EB558Cc3b56cA6d32;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x3ac4e9aa29940770aeC38fe853a4bbabb2dA9C19;

  address internal constant WETH_GATEWAY = 0xAeBF56223F044a73A513FAD7E148A9075227eD9b;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x35784a624D4FfBC3594f4d16fA3801FeF063241c;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0xE84cF064a0a65290Ae5673b500699f3753063936;

  address internal constant LISTING_ENGINE = 0x9eCed0293e7B73CFf4a2b4F9C82aAc8346158bd9;

  address internal constant RATES_FACTORY = 0xD05003a24A17d9117B11eC04cF9743b050779c08;

  address internal constant MIGRATION_HELPER = 0x3db487975aB1728DB5787b798866c2021B24ec52;

  address internal constant WALLET_BALANCE_PROVIDER = 0x34aa032bC416Cf2CdC45c0C8f065b1F19463D43e;

  address internal constant UI_POOL_DATA_PROVIDER = 0x204f2Eb81D996729829debC819f7992DCEEfE7b1;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x645654D59A5226CBab969b1f5431aA47CBf64ab8;
}

library AaveV2PolygonAssets {
  address internal constant DAI_UNDERLYING = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
  address internal constant DAI_A_TOKEN = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;
  address internal constant DAI_V_TOKEN = 0x75c4d1Fb84429023170086f06E682DcbBF537b7d;
  address internal constant DAI_S_TOKEN = 0x2238101B7014C279aaF6b408A284E49cDBd5DB55;
  address internal constant DAI_ORACLE = 0xFC539A559e170f848323e19dfD66007520510085;
  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xbE889f70c89f36eB34680b26162Fd84ffd6fE355;

  address internal constant USDC_UNDERLYING = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address internal constant USDC_A_TOKEN = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;
  address internal constant USDC_V_TOKEN = 0x248960A9d75EdFa3de94F7193eae3161Eb349a12;
  address internal constant USDC_S_TOKEN = 0xdeb05676dB0DB85cecafE8933c903466Bf20C572;
  address internal constant USDC_ORACLE = 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE;
  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xe7a516f340a3f794a3B2fd0f74A7242b326b9f33;

  address internal constant USDT_UNDERLYING = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address internal constant USDT_A_TOKEN = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;
  address internal constant USDT_V_TOKEN = 0x8038857FD47108A07d1f6Bf652ef1cBeC279A2f3;
  address internal constant USDT_S_TOKEN = 0xe590cfca10e81FeD9B0e4496381f02256f5d2f61;
  address internal constant USDT_ORACLE = 0xf9d5AAC6E5572AEFa6bd64108ff86a222F69B64d;
  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xD2C92b5A793e196aB11dBefBe3Af6BddeD6c3DD5;

  address internal constant WBTC_UNDERLYING = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
  address internal constant WBTC_A_TOKEN = 0x5c2ed810328349100A66B82b78a1791B101C9D61;
  address internal constant WBTC_V_TOKEN = 0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC;
  address internal constant WBTC_S_TOKEN = 0x2551B15dB740dB8348bFaDFe06830210eC2c2F13;
  address internal constant WBTC_ORACLE = 0xA338e0492B2F944E9F8C0653D3AD1484f2657a37;
  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x1d41b83e5bdbB21c4dD924507cBde66CD865d029;

  address internal constant WETH_UNDERLYING = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address internal constant WETH_A_TOKEN = 0x28424507fefb6f7f8E9D3860F56504E4e5f5f390;
  address internal constant WETH_V_TOKEN = 0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5;
  address internal constant WETH_S_TOKEN = 0xc478cBbeB590C76b01ce658f8C4dda04f30e2C6f;
  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;
  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0xD792a3779D3C80bAEe8CF3304D6aEAc74bC432BE;

  address internal constant WMATIC_UNDERLYING = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address internal constant WMATIC_A_TOKEN = 0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4;
  address internal constant WMATIC_V_TOKEN = 0x59e8E9100cbfCBCBAdf86b9279fa61526bBB8765;
  address internal constant WMATIC_S_TOKEN = 0xb9A6E29fB540C5F1243ef643EB39b0AcbC2e68E3;
  address internal constant WMATIC_ORACLE = 0x327e23A4855b6F663a28c5161541d69Af8973302;
  address internal constant WMATIC_INTEREST_RATE_STRATEGY =
    0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9;

  address internal constant AAVE_UNDERLYING = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
  address internal constant AAVE_A_TOKEN = 0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360;
  address internal constant AAVE_V_TOKEN = 0x1c313e9d0d826662F5CE692134D938656F681350;
  address internal constant AAVE_S_TOKEN = 0x17912140e780B29Ba01381F088f21E8d75F954F9;
  address internal constant AAVE_ORACLE = 0xbE23a3AA13038CfC28aFd0ECe4FdE379fE7fBfc4;
  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0xae9b3Eb616ed753dcE96C75B6AE30A60Ff9290B4;

  address internal constant GHST_UNDERLYING = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
  address internal constant GHST_A_TOKEN = 0x080b5BF8f360F624628E0fb961F4e67c9e3c7CF1;
  address internal constant GHST_V_TOKEN = 0x36e988a38542C3482013Bb54ee46aC1fb1efedcd;
  address internal constant GHST_S_TOKEN = 0x6A01Db46Ae51B19A6B85be38f1AA102d8735d05b;
  address internal constant GHST_ORACLE = 0xe638249AF9642CdA55A92245525268482eE4C67b;
  address internal constant GHST_INTEREST_RATE_STRATEGY =
    0xBb480ae4e2cf28FBE80C9b61ab075f6e7C4dB468;

  address internal constant BAL_UNDERLYING = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
  address internal constant BAL_A_TOKEN = 0xc4195D4060DaEac44058Ed668AA5EfEc50D77ff6;
  address internal constant BAL_V_TOKEN = 0x773E0e32e7b6a00b7cA9daa85dfba9D61B7f2574;
  address internal constant BAL_S_TOKEN = 0xbC30bbe0472E0E86b6f395f9876B950A13B23923;
  address internal constant BAL_ORACLE = 0x03CD157746c61F44597dD54C6f6702105258C722;
  address internal constant BAL_INTEREST_RATE_STRATEGY = 0x54DA5057cdA764909f4c79bA9fbb2d4A214EeAe5;

  address internal constant DPI_UNDERLYING = 0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369;
  address internal constant DPI_A_TOKEN = 0x81fB82aAcB4aBE262fc57F06fD4c1d2De347D7B1;
  address internal constant DPI_V_TOKEN = 0x43150AA0B7e19293D935A412C8607f9172d3d3f3;
  address internal constant DPI_S_TOKEN = 0xA742710c0244a8Ebcf533368e3f0B956B6E53F7B;
  address internal constant DPI_ORACLE = 0xC70aAF9092De3a4E5000956E672cDf5E996B4610;
  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x6405F880E431403588e92b241Ca15603047ef8a4;

  address internal constant CRV_UNDERLYING = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
  address internal constant CRV_A_TOKEN = 0x3Df8f92b7E798820ddcCA2EBEA7BAbda2c90c4aD;
  address internal constant CRV_V_TOKEN = 0x780BbcBCda2cdb0d2c61fd9BC68c9046B18f3229;
  address internal constant CRV_S_TOKEN = 0x807c97744e6C9452e7C2914d78f49d171a9974a0;
  address internal constant CRV_ORACLE = 0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4;
  address internal constant CRV_INTEREST_RATE_STRATEGY = 0xE4621DfD503A533f42bB5a45162eA3e5233Acd5F;

  address internal constant SUSHI_UNDERLYING = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
  address internal constant SUSHI_A_TOKEN = 0x21eC9431B5B55c5339Eb1AE7582763087F98FAc2;
  address internal constant SUSHI_V_TOKEN = 0x9CB9fEaFA73bF392C905eEbf5669ad3d073c3DFC;
  address internal constant SUSHI_S_TOKEN = 0x7Ed588DCb30Ea11A54D8a5E9645960262A97cd54;
  address internal constant SUSHI_ORACLE = 0x17414Eb5159A082e8d41D243C1601c2944401431;
  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x835699Bf98f6a7fDe5713c42c118Fb80fA059737;

  address internal constant LINK_UNDERLYING = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
  address internal constant LINK_A_TOKEN = 0x0Ca2e42e8c21954af73Bc9af1213E4e81D6a669A;
  address internal constant LINK_V_TOKEN = 0xCC71e4A38c974e19bdBC6C0C19b63b8520b1Bb09;
  address internal constant LINK_S_TOKEN = 0x9fb7F546E60DDFaA242CAeF146FA2f4172088117;
  address internal constant LINK_ORACLE = 0xb77fa460604b9C6435A235D057F7D319AC83cb53;
  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x5641Bb58f4a92188A6F16eE79C8886Cf42C561d3;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveV2ConfigEngine as IEngine} from './IAaveV2ConfigEngine.sol';
import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 configs update.
 * - Assumes this contract has the right permissions
 * - Connected to a IAaveV2ConfigEngine engine contact, which abstract the complexities of
 *   interaction with the Aave protocol.
 * - At the moment covering:
 *    Updates of interest rate strategies.
 * @author BGD Labs
 */
abstract contract AaveV2PayloadBase {
  using Address for address;

  IEngine public immutable LISTING_ENGINE;

  constructor(IEngine engine) {
    LISTING_ENGINE = engine;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    IEngine.RateStrategyUpdate[] memory rates = rateStrategiesUpdates();

    if (rates.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateRateStrategies.selector, rates)
      );
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function rateStrategiesUpdates()
    public
    view
    virtual
    returns (IEngine.RateStrategyUpdate[] memory)
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import {AggregatorInterface} from './common/AggregatorInterface.sol';

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(
    address reserve,
    address rateStrategyAddress
  ) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(
    address user
  ) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

interface ILendingPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
   **/
  event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when stable rate borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when an aToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Initializes a reserve
   * @param aTokenImpl  The address of the aToken contract implementation
   * @param stableDebtTokenImpl The address of the stable debt token contract
   * @param variableDebtTokenImpl The address of the variable debt token contract
   * @param underlyingAssetDecimals The decimals of the reserve underlying asset
   * @param interestRateStrategyAddress The address of the interest rate strategy contract for this reserve
   **/
  function initReserve(
    address aTokenImpl,
    address stableDebtTokenImpl,
    address variableDebtTokenImpl,
    uint8 underlyingAssetDecimals,
    address interestRateStrategyAddress
  ) external;

  function batchInitReserve(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateAToken(address asset, address implementation) external;

  /**
   * @dev Updates the stable debt token implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateStableDebtToken(address asset, address implementation) external;

  /**
   * @dev Updates the variable debt token implementation for the asset
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateVariableDebtToken(address asset, address implementation) external;

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external;

  /**
   * @dev Configures the reserve collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @dev Enable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableReserveStableRate(address asset) external;

  /**
   * @dev Disable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableReserveStableRate(address asset) external;

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external;

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external;

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
   *  but allows repayments, liquidations, rate rebalances and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external;

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external;

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external;

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @dev pauses or unpauses all the actions of the protocol, including aToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external;
}

interface IAaveOracle {
  event WethSet(address indexed weth);
  event AssetSourceUpdated(address indexed asset, address indexed source);
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /// @notice Returns the WETH address (reference asset of the oracle)
  function WETH() external returns (address);

  /// @notice External function called by the Aave governance to set or replace sources of assets
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /// @notice Sets the fallbackOracle
  /// - Callable only by the Aave governance
  /// @param fallbackOracle The address of the fallbackOracle
  function setFallbackOracle(address fallbackOracle) external;

  /// @notice Gets an asset price by address
  /// @param asset The asset address
  function getAssetPrice(address asset) external view returns (uint256);

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /// @notice Gets the address of the source for an asset address
  /// @param asset The address of the asset
  /// @return address The address of the source
  function getSourceOfAsset(address asset) external view returns (address);

  /// @notice Gets the address of the fallback oracle
  /// @return address The addres of the fallback oracle
  function getFallbackOracle() external view returns (address);
}

struct TokenData {
  string symbol;
  address tokenAddress;
}

// TODO: incomplete interface
interface IAaveProtocolDataProvider {
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );
}

interface ILendingRateOracle {
  /**
    @dev returns the market borrow rate in ray
    **/
  function getMarketBorrowRate(address asset) external view returns (uint256);

  /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
  function setMarketBorrowRate(address asset, uint256 rate) external;
}

interface IDefaultInterestRateStrategy {
  function EXCESS_UTILIZATION_RATE() external view returns (uint256);

  function OPTIMAL_UTILIZATION_RATE() external view returns (uint256);

  function addressesProvider() external view returns (address);

  function baseVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  ) external view returns (uint256, uint256, uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function stableRateSlope1() external view returns (uint256);

  function stableRateSlope2() external view returns (uint256);

  function variableRateSlope1() external view returns (uint256);

  function variableRateSlope2() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title ICollector
 * @notice Defines the interface of the Collector contract
 * @author Aave
 **/
interface ICollector {
  struct Stream {
    uint256 deposit;
    uint256 ratePerSecond;
    uint256 remainingBalance;
    uint256 startTime;
    uint256 stopTime;
    address recipient;
    address sender;
    address tokenAddress;
    bool isEntity;
  }

  /** @notice Emitted when the funds admin changes
   * @param fundsAdmin The new funds admin.
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /** @notice Emitted when the new stream is created
   * @param streamId The identifier of the stream.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   **/
  event CreateStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  );

  /**
   * @notice Emmitted when withdraw happens from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param recipient The address towards which the money is streamed.
   * @param amount The amount of tokens to withdraw.
   */
  event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

  /**
   * @notice Emmitted when the stream is canceled.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param senderBalance The sender's balance at the moment of cancelling.
   * @param recipientBalance The recipient's balance at the moment of cancelling.
   */
  event CancelStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 senderBalance,
    uint256 recipientBalance
  );

  /** @notice Returns the mock ETH reference address
   * @return address The address
   **/
  function ETH_MOCK_ADDRESS() external pure returns (address);

  /** @notice Initializes the contracts
   * @param fundsAdmin Funds admin address
   * @param nextStreamId StreamId to set, applied if greater than 0
   **/
  function initialize(address fundsAdmin, uint256 nextStreamId) external;

  /**
   * @notice Return the funds admin, only entity to be able to interact with this contract (controller of reserve)
   * @return address The address of the funds admin
   **/
  function getFundsAdmin() external view returns (address);

  /**
   * @notice Returns the available funds for the given stream id and address.
   * @param streamId The id of the stream for which to query the balance.
   * @param who The address for which to query the balance.
   * @notice Returns the total funds allocated to `who` as uint256.
   */
  function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

  /**
   * @dev Function for the funds admin to give ERC20 allowance to other parties
   * @param token The address of the token to give allowance from
   * @param recipient Allowance's recipient
   * @param amount Allowance to approve
   **/
  function approve(
    //IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Function for the funds admin to transfer ERC20 tokens to other parties
   * @param token The address of the token to transfer
   * @param recipient Transfer's recipient
   * @param amount Amount to transfer
   **/
  function transfer(
    //IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;

  /**
   * @notice Creates a new stream funded by this contracts itself and paid towards `recipient`.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   * @return streamId the uint256 id of the newly created stream.
   */
  function createStream(
    address recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external returns (uint256 streamId);

  /**
   * @notice Returns the stream with all its properties.
   * @dev Throws if the id does not point to a valid stream.
   * @param streamId The id of the stream to query.
   * @notice Returns the stream object.
   */
  function getStream(
    uint256 streamId
  )
    external
    view
    returns (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,
      uint256 ratePerSecond
    );

  /**
   * @notice Withdraws from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param amount The amount of tokens to withdraw.
   * @return bool Returns true if successful.
   */
  function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);

  /**
   * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
   * @param streamId The id of the stream to cancel.
   * @return bool Returns true if successful.
   */
  function cancelStream(uint256 streamId) external returns (bool);

  /**
   * @notice Returns the next available stream id
   * @return nextStreamId Returns the stream id.
   */
  function getNextStreamId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), 'Address: call to non-contract');
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   */
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   */
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   */
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   */
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolConfigurator} from 'aave-address-book/AaveV2.sol';
import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';

/// @dev Examples here assume the usage of the `AaveV2PayloadBase` base contracts
/// contained in this same repository
interface IAaveV2ConfigEngine {
  /**
   * @dev Example (mock):
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock):
   * RateStrategyUpdate({
   *   asset: AaveV2EthereumAssets.AAVE_UNDERLYING,
   *   params: IV2RateStrategyFactory.RateStrategyParams({
   *     optimalUtilizationRate: _bpsToRay(80_00),
   *     baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     stableRateSlope2: _bpsToRay(75_00),
   *   })
   * })
   */
  struct RateStrategyUpdate {
    address asset;
    IV2RateStrategyFactory.RateStrategyParams params;
  }

  /**
   * @notice Performs an update on the rate strategy params of the assets, in the Aave pool configured in this engine instance
   * @dev The engine itself manages if a new rate strategy needs to be deployed or if an existing one can be re-used
   * @param updates `RateStrategyUpdate[]` list of declarative updates containing the new rate strategy params
   *   More information on the documentation of the struct.
   */
  function updateRateStrategies(RateStrategyUpdate[] memory updates) external;

  function RATE_STRATEGIES_FACTORY() external view returns (IV2RateStrategyFactory);

  function POOL_CONFIGURATOR() external view returns (ILendingPoolConfigurator);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDefaultInterestRateStrategy, ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';

interface IV2RateStrategyFactory {
  event RateStrategyCreated(
    address indexed strategy,
    bytes32 indexed hashedParam,
    RateStrategyParams params
  );

  /// @dev same parameters and the ones received on the constructor of DefaultReserveInterestRateStrategy
  /// in practise defining the strategy itself
  struct RateStrategyParams {
    uint256 optimalUtilizationRate;
    uint256 baseVariableBorrowRate;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
  }

  /**
   * @notice Create new rate strategies from a list of parameters
   * @dev If a strategy with exactly the same `RateStrategyParams` already exists, no creation happens but
   *  its address is returned
   * @param params `RateStrategyParams[]` list of parameters for multiple strategies
   * @return address[] list of strategies
   */
  function createStrategies(RateStrategyParams[] memory params) external returns (address[] memory);

  /**
   * @notice Returns the identifier of a rate strategy from its parameters
   * @param params `RateStrategyParams` the parameters of the rate strategy
   * @return bytes32 the keccak256 hash generated from the `RateStrategyParams` parameters
   *   to be used as identifier of the rate strategy on the factory
   */
  function strategyHashFromParams(RateStrategyParams memory params) external pure returns (bytes32);

  /**
   * @notice Returns all the strategies registered in the factory
   * @return address[] list of strategies
   */
  function getAllStrategies() external view returns (address[] memory);

  /**
   * @notice Returns the a strategy added, given its parameters.
   * @dev Only if the strategy is registered in the factory.
   * @param params `RateStrategyParams` the parameters of the rate strategy
   * @return address the address of the strategy
   */
  function getStrategyByParams(RateStrategyParams memory params) external view returns (address);

  /**
   * @notice From an asset in the Aave v3 pool, returns exclusively its parameters
   * @param asset The address of the asset
   * @return RateStrategyParams The parameters or the strategy, or empty RateStrategyParams struct
   */
  function getStrategyDataOfAsset(address asset) external view returns (RateStrategyParams memory);

  /**
   * @notice From a rate strategy address, returns its parameters
   * @param strategy The address of the rate strategy
   * @return RateStrategyParams Struct with the parameters of the strategy
   */
  function getStrategyData(IDefaultInterestRateStrategy strategy)
    external
    view
    returns (RateStrategyParams memory);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EngineFlags {
  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `type(uint256).max - 42` will never be used, which seems reasonable
  uint256 internal constant KEEP_CURRENT = type(uint256).max - 42;

  /// @dev value to be used as flag for bool value true
  uint256 internal constant ENABLED = 1;

  /// @dev value to be used as flag for bool value false
  uint256 internal constant DISABLED = 0;

  /// @dev converts flag ENABLED DISABLED to bool
  function toBool(uint256 flag) internal pure returns (bool) {
    require(flag == 0 || flag == 1, 'INVALID_CONVERSION_TO_BOOL');
    return flag == 1;
  }

  /// @dev converts bool to ENABLED DISABLED flags
  function fromBool(bool isTrue) internal pure returns (uint256) {
    return isTrue ? ENABLED : DISABLED;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}