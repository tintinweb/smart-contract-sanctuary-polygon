// SPDX-License-Identifier: AGPL-3.0
    pragma solidity 0.8.10;

    pragma experimental ABIEncoderV2;
    interface IProposalGenericExecutor {
      struct ProposalPayload {
        address underlyingAsset;
        address interestRateStrategy;
        address oracle;
        uint256 ltv;
        uint256 lt;
        uint256 lb;
        uint256 rf;
        uint8 decimals;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        string underlyingAssetName;
      }
    
      function execute() external;
    }
    
    interface IPoolConfigurator {
      struct InitReserveInput {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        bytes params;
      }
    
      function initReserves(InitReserveInput[] calldata input) external;
    
      function setReserveBorrowing(address asset, bool enabled) external;
    
      function setReserveStableRateBorrowing(address asset, bool enabled) external;

      function setReserveFactor(address asset, uint256 newReserveFactor) external;

      function setAssetEModeCategory(address asset, uint8 newCategoryId) external;
    
      function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
      ) external;
    }
    
    interface IAaveOracle {
      function setAssetSources(address[] calldata assets, address[] calldata sources) external;
    }
    
    interface IPoolAddressesProvider {
      function getPool() external view returns (address);
    
      function getPoolConfigurator() external view returns (address);
    }
    
    /**
     * @title AssetListingProposalGenericExecutor
     * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
     * @author Goman & Zoe
     **/
    contract PolygonAssetDeploymentGenericExecutor is IProposalGenericExecutor {
      event ProposalExecuted();
    
      IPoolAddressesProvider public constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);
      IAaveOracle public constant AAVE_ORACLE = IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);
    
      address public constant TREASURY_ADDRESS = 0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383;
      address public constant INCENTIVES_CONTROLLER_ADDRESS = 0x929EC64c34a17401F460460D4B9390518E5B473e;
      address public constant ATOKEN_ADDRESS = 0x9a100a26364Fa2f3675A7F98DA4335fde3380a55;
      address public constant VAR_IMPL_ADDRESS = 0xEc08Ecd5b48bec7A605DB53161ebce17b9863a36;
      address public constant STABLE_IMPL_ADDRESS = 0xfbFe91E6e013fD8611ECd43f237B0687C6ebC3Dc;
      address public constant TUSD_INTEREST_RATE_STRATEGY = 0x5EeA902c9944D0353A9DEd6Eb4f15c53Ff3A8589;
    
      string public constant ATOKEN_NAME_PREFIX = "Aave Matic Market ";
      string public constant ATOKEN_SYMBOL_PREFIX = "am";
      string public constant VAR_DEBT_NAME_PREFIX = "Aave Matic Market variable debt ";
      string public constant VAR_DEBT_SYMBOL_PREFIX = "variableDebtm";
      string public constant STABLE_DEBT_NAME_PREFIX = "Aave Matic Market stable debt ";
      string public constant STABLE_DEBT_SYMBOL_PREFIX = "stableDebtm";
      bytes public constant param = "";
    
      address public constant TUSD_UNDERLYING_ASSET = 0x2e1AD108fF1D8C782fcBbB89AAd783aC49586756;
      address public constant TUSD_ORACLE = 0x7C5D415B64312D38c56B54358449d0a4058339d2;
      uint256 public constant TUSD_LTV = 8000;
      uint256 public constant TUSD_LT = 8250;
      uint256 public constant TUSD_LB = 10500;
      uint256 public constant TUSD_RF = 1000;
      uint8 public constant TUSD_DECIMALS = 18;
      bool public constant TUSD_BORROW_ENABLED = true;
      bool public constant TUSD_STABLE_BORROW_ENABLED = true;
      string public constant TUSD_UNDERLYING_ASSET_NAME = "TUSD";

      uint8 public constant EMODE_CATEGORY_USD = 1;
    
      /**
       * @dev Payload execution function, called once a proposal passed in the Aave governance
       */
      function execute() external override {

        IProposalGenericExecutor.ProposalPayload[1] memory proposalPayloads;
        proposalPayloads[0] = ProposalPayload({
          underlyingAsset: TUSD_UNDERLYING_ASSET,
          interestRateStrategy: TUSD_INTEREST_RATE_STRATEGY,
          oracle: TUSD_ORACLE,
          ltv: TUSD_LTV,
          lt: TUSD_LT,
          lb: TUSD_LB,
          rf: TUSD_RF,
          decimals: TUSD_DECIMALS,
          borrowEnabled: TUSD_BORROW_ENABLED,
          stableBorrowEnabled: TUSD_STABLE_BORROW_ENABLED,
          underlyingAssetName: TUSD_UNDERLYING_ASSET_NAME
        });

        IPoolConfigurator POOL_CONFIGURATOR = IPoolConfigurator(
          POOL_ADDRESSES_PROVIDER.getPoolConfigurator()
        );

        IPoolConfigurator.InitReserveInput[]
          memory initReserveInput = new IPoolConfigurator.InitReserveInput[](1);
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);

        //Fill up the init reserve input
        for (uint256 i = 0; i < 1; i++) {
          ProposalPayload memory payload = proposalPayloads[i];
          assets[i] = payload.underlyingAsset;
          sources[i] = payload.oracle;
          initReserveInput[i] = IPoolConfigurator.InitReserveInput({
            aTokenImpl:ATOKEN_ADDRESS,
            stableDebtTokenImpl: STABLE_IMPL_ADDRESS,
            variableDebtTokenImpl: VAR_IMPL_ADDRESS,
            underlyingAssetDecimals: payload.decimals,
            interestRateStrategyAddress: payload.interestRateStrategy,
            underlyingAsset: payload.underlyingAsset,
            treasury: TREASURY_ADDRESS,
            incentivesController: INCENTIVES_CONTROLLER_ADDRESS,
            aTokenName: string(abi.encodePacked(ATOKEN_NAME_PREFIX, payload.underlyingAssetName)),
            aTokenSymbol:string(abi.encodePacked(ATOKEN_SYMBOL_PREFIX, payload.underlyingAssetName)) ,
            variableDebtTokenName: string(abi.encodePacked(VAR_DEBT_NAME_PREFIX, payload.underlyingAssetName)),
            variableDebtTokenSymbol: string(abi.encodePacked(VAR_DEBT_SYMBOL_PREFIX, payload.underlyingAssetName)),
            stableDebtTokenName: string(abi.encodePacked(STABLE_DEBT_NAME_PREFIX, payload.underlyingAssetName)),
            stableDebtTokenSymbol:string(abi.encodePacked(STABLE_DEBT_SYMBOL_PREFIX, payload.underlyingAssetName)),
            params: param
          });
        }

        //initiate the reserves and add oracles
        POOL_CONFIGURATOR.initReserves(initReserveInput);

        AAVE_ORACLE.setAssetSources(assets, sources);
        

        //now initialize the rest of the parameters
        for (uint256 i = 0; i < 1; i++) {
          ProposalPayload memory payload = proposalPayloads[i];
          POOL_CONFIGURATOR.configureReserveAsCollateral(
            payload.underlyingAsset,
            payload.ltv,
            payload.lt,
            payload.lb
          ); 

          if (payload.borrowEnabled) {
              POOL_CONFIGURATOR.setReserveBorrowing(
                  payload.underlyingAsset,
                  payload.borrowEnabled
              );
          }

          if (payload.stableBorrowEnabled) {
            POOL_CONFIGURATOR.setReserveStableRateBorrowing(
              payload.underlyingAsset,
              payload.stableBorrowEnabled
            );
          }   

          POOL_CONFIGURATOR.setReserveFactor(
              payload.underlyingAsset,
              payload.rf
          );

          POOL_CONFIGURATOR.setAssetEModeCategory(payload.underlyingAsset, EMODE_CATEGORY_USD);
        }
    
        emit ProposalExecuted();
      }
    }