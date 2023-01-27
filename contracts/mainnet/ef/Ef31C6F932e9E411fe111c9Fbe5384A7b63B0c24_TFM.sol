// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";

import {Utils} from "../libraries/Utils.sol";
import {TFMStorage} from "./TFMStorage.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CollateralManager} from "./CollateralManager.sol";
import {ITFM} from "../interfaces/ITFM.sol";

uint16 constant BP = 10_000;

/** IDEA
- / Calculate fee once and store in action struct (DONE CS: 20.954)
- / Create peppermintExecute in CM (DONE CS: -0.70)
- / Move liquidation into CM as proxy (DONE CS: -0.36)
- / Move reallocateCollateral calculation into CM (DONE)
- Move requiredcollateral calculation into CM (in spearmint, claim, transfer, etc...)
- Add fee confiscation umbrella function into CM (in novate we only confiscate from one)

- Make structs for proxy functions (e.g. LiquidationParams, ReallocateCollateralParams, etc.)
*/

// TODO: add LIQUIDATOR address

/**
    @title TFM provides a framework for creating / using custom option strategies.
    @notice  This is a framework allowing for partial collateralisation of bidirectional options strategies.
    A TradFi parallel can be drawn to ISDA (International Swaps and Derivatives Association), which
    offers a framework of procedures and legal contracts for parties to enter into derivative contracts
    with each other. This layer has no whitelisting or KYC.
    @dev Additional documentation can be found on notion @ https://www.notion.so/trufin/V2-Documentation-6a7a43f8b577411d84277fc543f99063?d=63b28d74feba48c6be7312709a31dbe9#5bff636f9d784712af5de7df0a19ea72
*/
contract TFM is
    TFMStorage,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ITFM
{
    using Utils for int256;
    using Utils for int256[2][];

    /************************************************
     *  Initialisation
     ***********************************************/

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    constructor() {
        _disableInitializers();
    }

    //@param _LiquidationFee is the liquidation fee collected by the Treasury specified as a percentage.
    /**
        @notice Initialises the contract
        @param _collateralManager is the address of the Collateral Manager contract.
        @param _owner is the address of the Owner.
        @param _Polaron is the fee taken for minting and claiming.
        @param _Proton is the fee taken for transfers.
        @param _Electron is the fee taken for combinations.
        @param _Neutron is the fee taken for novations.
    */
    function initialize(
        address _collateralManager,
        address _owner,
        address _LiquidatorAddress,
        uint256 _Polaron,
        uint256 _Proton,
        uint256 _Electron,
        uint256 _Neutron
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(_owner);
        LiquidatorAddress = _LiquidatorAddress;
        collateralManager = CollateralManager(_collateralManager);
        particles[ActionType.CLAIM] = _Polaron;
        particles[ActionType.TRANSFER] = _Proton;
        particles[ActionType.COMBINATION] = _Electron;
        particles[ActionType.NOVATION] = _Neutron;
        // positron is liquidation fee
    }

    /************************************************
     *  Setters / Getters / Modifiers
     ***********************************************/

    /**
     @notice Used to get action counter of a user based on which is greater
     @param user1 User 1 address
     @param user2 user 2 address
      */

    function getUserPairCounter(address user1, address user2)
        public
        view
        returns (uint256)
    {
        return
            userPairCounter[user1 < user2 ? user1 : user2][
                user1 < user2 ? user2 : user1
            ];
    }

    /**
        @notice Used to get info on a strategy.
        @param _strategyID ID of strategy to get.
        @return Strategy struct corresponding to _strategyID.
    */
    function getStrategy(uint256 _strategyID)
        external
        view
        returns (Strategy memory)
    {
        return strategies[_strategyID];
    }

    /**
        @dev Helper function to compute the particleMass for a given strategy and actionType
        (this corresponds to the fees charged to execute a given operation on a given strategy)
        @param _strategyID the ID of the strategy to compute the particleMass for
        @param _actionType the action for which the particleMass should be computed
        @return particleMass the particleMass for the above
    */
    function getParticleMass(uint256 _strategyID, ActionType _actionType)
        internal
        view
        returns (uint256)
    {
        return
            (strategies[_strategyID].maxNotional *
                strategies[_strategyID].amplitude.abs() *
                particles[_actionType]) / BP;
    }

    /**
        @notice Function for admin to set the Liquidator address.
        @param _LiquidatorAddress the Liquidator address
    */
    function setLiquidatorAddress(address _LiquidatorAddress) public onlyOwner {
        LiquidatorAddress = _LiquidatorAddress;
    }

    /**
        @notice Checks if msg.sender is Liquidator.
    */
    modifier isLiquidator() {
        require(msg.sender == LiquidatorAddress, "A1");
        _;
    }

    /**
        @notice Admin function to set photon mass.
        @dev See initializer/storage for info on photons.
        @param _basis basis to set the mass of.
        @param _mass mass of photon.
    */
    function setPhoton(address _basis, uint256 _mass) external onlyOwner {
        photons[_basis] = _mass;
    }

    /**
        @notice Setter for particles.
        @dev See initializer/storage for info on particles.
        @param _action action type to set a mass for.
        @param _mass mass of particle.
    */
    function setParticle(ActionType _action, uint256 _mass) external onlyOwner {
        particles[_action] = _mass;
    }

    /**
        @notice Modifier to check if two strategies are compatible in terms of basis and expiry
        and that they are not expired.
        @param _thisStrategyID the ID of one of the strategies to compare
        @param _targetStrategyID the ID of the other strategy to compare against
    */
    function strategiesCompatible(
        bytes calldata _sigWeb2,
        uint256 _thisStrategyID,
        uint256 _targetStrategyID,
        uint256 _collateralNonce
    ) internal view {
        require(
            strategies[_thisStrategyID].bra ==
                strategies[_targetStrategyID].bra &&
                strategies[_thisStrategyID].ket ==
                strategies[_targetStrategyID].ket &&
                strategies[_thisStrategyID].basis ==
                strategies[_targetStrategyID].basis,
            "S33" // "strategies must have the same bra, ket, and basis"
        );

        require(
            strategies[_thisStrategyID].expiry ==
                strategies[_targetStrategyID].expiry,
            "S32" // "strategies must share the same expiry"
        );
        {
            Utils.checkWeb2SignatureForExpiry(
                _sigWeb2,
                collateralManager.Web2Address(),
                _collateralNonce,
                strategies[_thisStrategyID].expiry
            );
        }
    }

    /************************************************
     *  Collateral Management
     ***********************************************/

    /**
        @notice Function to check collateral requirements are valid, i.e.: they are signed by the web2 backend & 
        the parameters were not modified by the usre & the data is up-to-date (through the Collateral Manager).
        @dev The collateral information only specifies strategyID, and the parameters are read from storage to ensure
        that they have not been updated on chain.
        @param _paramsID struct containing the parameters (strategyID, collateral requirements, collateralNonce)
        @param _signature web2 signature of hashed message
    */
    function checkCollateralRequirements(
        CollateralParamsID memory _paramsID,
        bytes calldata _signature
    ) public view {
        Strategy storage strategy = strategies[_paramsID.strategyID];

        // Read strategy params from storage to ensure that collateral information from web2 should still be valid.
        CollateralParamsFull memory params = CollateralParamsFull(
            strategy.expiry,
            _paramsID.alphaCollateralRequirement,
            _paramsID.omegaCollateralRequirement,
            _paramsID.collateralNonce,
            strategy.bra,
            strategy.ket,
            strategy.basis,
            strategy.amplitude,
            strategy.maxNotional,
            strategy.phase
        );

        Utils.checkWeb2Signature(
            params,
            _signature,
            collateralManager.collateralNonce(),
            collateralManager.Web2Address()
        );
    }

    /**
        @notice Function to reallocate collateral from a strategy to anther strategy or to the unallocated pool.
        @dev This function verifies that both collateral requirements and premium requirements are not violated by reallocation
        (i.e.: that fromStrategy is sufficiently collateralised after the reallocation and that any posted premium pending withdrawal is retained).
        Whereas, the actual reallocation happens through the Collateral Manager.
        Note basis will be inferred from fromStrategy
        @param _fromStrategyID ID of strategy to move collateral from
        @param _toStrategyID ID of strategy to move collateral to (note if this is 0, we move collateral to the unallocated pool)
        @param _amount amount of collateral to move
        @param _paramsID struct containing the parameters (strategyID, collateral requirements, collateralNonce)
        @param _signature web2 signature of hashed message
    */
    function reallocateCollateral(
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _amount,
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature
    ) external nonReentrant {
        // Verify if collateral information provided is valid and sufficiently up-to-date.
        // Note we use the internal helper function to read the strategy params from storage.
        checkCollateralRequirements(_paramsID, _signature);

        Strategy storage fromStrategy = strategies[_fromStrategyID];
        Strategy storage toStrategy = strategies[_toStrategyID];

        // Ensure that either rellocation is done to unallocated pool, or that the strategies share a basis.
        require(
            _toStrategyID == 0 || fromStrategy.basis == toStrategy.basis,
            "S31" // "strategy basis must be the same"
        );

        collateralManager.reallocateCollateral(
            ReallocateCollateralRequest(
                msg.sender,
                fromStrategy.alpha,
                fromStrategy.omega,
                _paramsID.alphaCollateralRequirement,
                _paramsID.omegaCollateralRequirement,
                _fromStrategyID,
                _toStrategyID,
                _amount,
                fromStrategy.basis
            )
        );
    }

    /************************************************
     *  Strategy Minting
     ***********************************************/

    /**
        @dev Helper function to create new strategy struct with a unique id.
        @param strategy the Strategy struct to be created
    */
    function _newStrategy(Strategy memory strategy) internal {
        strategyCounter++;
        strategies[strategyCounter] = strategy;
    }

    /**
        @notice Function to mint a strategy. This function ensures that both alpha and omega are sufficiently collateralised to take up their side 
        (or to the maximum level requried by the collateral requirements). Anyone can call this function,
        but for it to work it must be signed by alpha, omega, and the collateral manager.
        @dev Note there is a two hour expiration period, that starts when the collateral manager signs
        @param _cParams the collateral parameters of the strategy to be minted (SpearmintCollateralParams)
        @param _aParams the action parameters of the strategy to be minted (SpearmintActionParams)
        note if +ve the alpha (previously minter) needs to receive premium, if -ve the alpha (previously minter) needs to pay premium
    */
    function spearmint(
        CollateralParamsFull calldata _cParams,
        SpearmintParams calldata _aParams
    ) external {
        //check web2 collateral Manager has signed
        {
            Utils.checkWeb2Signature(
                _cParams,
                _aParams.sigWeb2,
                collateralManager.collateralNonce(),
                collateralManager.Web2Address()
            );
        }

        //check both alpha & omega have signed
        {
            Utils.checkSpearmintUserSignatures(
                _aParams,
                getUserPairCounter(_aParams.alpha, _aParams.omega)
            );
        }

        _newStrategy(
            Strategy(
                _aParams.transferable,
                _cParams.bra,
                _cParams.ket,
                _cParams.basis,
                _aParams.alpha,
                _aParams.omega,
                _cParams.expiry,
                _cParams.amplitude,
                _cParams.maxNotional,
                _cParams.phase
            )
        );

        uint256 particleMass = getParticleMass(
            strategyCounter,
            ActionType.CLAIM
        );

        updateUserCounter(_aParams.alpha, _aParams.omega);

        collateralManager.collateralLockExecute(
            CollateralLockRequest(
                _aParams.alpha,
                _aParams.omega,
                strategyCounter,
                particleMass,
                _aParams.alpha,
                _aParams.omega,
                _aParams.premium,
                _cParams.alphaCollateralRequirement,
                _cParams.omegaCollateralRequirement,
                _cParams.basis,
                false,
                false
            )
        );
    }

    /**
        @notice Function to mint a strategy for two parties by a third-party taking neither side of the strategy.
        This function ensures that _alpha and _omega are sufficiently collateralised to take up their side and
        that they have locked enough collateral to also cover any premium to be paid.
        In order to call this function, collateral requirements (from the Web2 backend) need to be sent.
        @dev This function is used by the auction house once an auction has completed, so that the 
        filled orders can be minted. At this stage, both parties involved in the strategy to be minted
        must have locked enough collateral (with the auction house as the trusted locker), to cover 
        collateral requirements and any premium to be paid. The collateral requirements must be provided
        by the auction initiator at the start of the auction.
        @param _params the parameters of the strategy to be minted (basis, expiry, amplitude, phase), 
        the collateral requirements and the collateral nonce (the version of the web2 database used to compute reqs)
        @param _transferable flag to indicate if strategy is transferable w/o requiring approval
        @param _alpha address to take alpha side of strategy
        @param _omega adddress to take omega side of strategy
        @param _signature signature of _hashedMessage by AdminAddress
        @param _premium amount of premium
        note if +ve premium is paid by _omega to _alpha, and vice-versa if premium is -ve
    */
    function peppermint(
        CollateralParamsFull calldata _params,
        bool _transferable,
        address _alpha,
        address _omega,
        bytes calldata _signature,
        int256 _premium
    ) external {
        // Valerii Review Comment:
        // _alpha and _omega are input parameters and caller can set any to pass next "require"
        // you should use other mechanism
        // Matyas Review Respons:
        // Again this is fine here as _alpha and _omega specify which parties should share the newly minted strategy.
        // Additionally, this call will only succeed if _alpha and _omega have both set the caller as a trusted locker
        // and have locked enough collateral to cover the collateral requirements + premium, to the caller.

        require((msg.sender != _alpha) && (msg.sender != _omega), "A22"); // "alpha and omega must not be msg.sender when pepperminting"

        // Verify if collateral information provided is valid and sufficiently up-to-date.
        // Note here we call the Collateral Manager directly as we have all strategy params specified in _params.
        Utils.checkWeb2Signature(
            _params,
            _signature,
            collateralManager.collateralNonce(),
            collateralManager.Web2Address()
        );

        _newStrategy(
            Strategy(
                _transferable,
                _params.bra,
                _params.ket,
                _params.basis,
                _alpha,
                _omega,
                _params.expiry,
                _params.amplitude,
                _params.maxNotional,
                _params.phase
            )
        );

        collateralManager.peppermintExecute(
            PeppermintRequest(
                msg.sender,
                strategyCounter,
                _alpha,
                _omega,
                _params.alphaCollateralRequirement,
                _params.omegaCollateralRequirement,
                _params.basis,
                _premium,
                getParticleMass(strategyCounter, ActionType.CLAIM)
            )
        );
    }

    /************************************************
     *  Actions
     ***********************************************/

    /**
        @notice Function to annihilate an existing strategy, if msg.caller is either
        on both sides of a strategy, or if they are on one side and the other side has not been claimed.
        Note this function also deallocates any collateral allocated to the strategy by msg.caller.
        @param _strategyID the ID of the strategy to annihilate
    */
    function annihilate(uint256 _strategyID) external {
        Strategy storage strategy = strategies[_strategyID];
        require(
            (strategy.alpha == msg.sender && strategy.omega == msg.sender) ||
                (strategy.alpha == address(0) &&
                    strategy.omega == msg.sender) ||
                (strategy.alpha == msg.sender && strategy.omega == address(0)),
            "A20" // "msg.sender not authorised to annihilate strategy"
        );

        // Deallocate any collateral allocated to the strategy about to be annihilated.
        collateralManager.reallocateAllNoCollateralCheck(
            msg.sender,
            _strategyID,
            0,
            strategy.basis
        );
        delete strategies[_strategyID]; // Delete strategy.
        delete strategyNonce[_strategyID];
    }

    /**
        @notice Function to update user counter by 1 in desc order of user addresses
        @param user1 Address of user 1
        @param user2 Address of user 2
     */
    function updateUserCounter(address user1, address user2) private {
        userPairCounter[user1 < user2 ? user1 : user2][
            user1 < user2 ? user2 : user1
        ]++;
    }

    /**
        @notice Function for the recepient (_targetUser) of an approved transfer to finalise the transfer and gain ownership
        of the specified side. This function ensures that the recepient is sufficiently collateralised and has posted any required premium.
        @dev This function optionally transfer premium from the transfer initiator to the recepient or vice-versa if it has been specified,
        and deallocates any allocated collateral of the transfer initiator if successfull.
        @param _cParams struct containing the full parameters
        @param _params struct containing the parametere like the 3-4 party signatures and target user, premium
    */

    function transfer(
        CollateralParamsFull calldata _cParams,
        TransferParams calldata _params
    ) external {
        Strategy storage strategy = strategies[_params.thisStrategyID];
        require(strategy.expiry > block.timestamp, "S1"); // "strategy must be active"

        {
            Utils.checkWeb2Signature(
                CollateralParamsFull(
                    strategy.expiry,
                    _cParams.alphaCollateralRequirement,
                    _cParams.omegaCollateralRequirement,
                    _cParams.collateralNonce,
                    strategy.bra,
                    strategy.ket,
                    strategy.basis,
                    strategy.amplitude,
                    strategy.maxNotional,
                    strategy.phase
                ),
                _params.sigWeb2,
                collateralManager.collateralNonce(),
                collateralManager.Web2Address()
            );
        }

        //check both alpha & omega have signed, return who signed first
        Utils.checkTransferUserSignatures(
            _params,
            strategy.alpha,
            strategy.omega,
            strategyNonce[_params.thisStrategyID],
            strategy.transferable
        );

        address transferer = _params.alphaTransfer
            ? strategy.alpha
            : strategy.omega;

        //Increase strategyNonce
        strategyNonce[_params.thisStrategyID]++;

        // Verify if collateral information provided is valid and sufficiently up-to-date.
        // Note we use the internal helper function to read the strategy params from storage.
        //checkCollateralRequirements(_hashedMessage, _paramsID, _signature); TODO REMOVE!

        //  If premium < 0: msg.sender is paying _targetUser.
        //  If premium > 0: _targetUser is paying msg.sender.
        uint256 particleMass = getParticleMass(
            _params.thisStrategyID,
            ActionType.TRANSFER
        );

        collateralManager.collateralLockExecute(
            CollateralLockRequest(
                transferer,
                _params.targetUser,
                _params.thisStrategyID,
                particleMass,
                strategy.alpha,
                strategy.omega,
                _params.premium,
                _cParams.alphaCollateralRequirement,
                _cParams.omegaCollateralRequirement,
                strategy.basis,
                _params.alphaTransfer,
                true
            )
        );

        // Deallocate initiators collateral as the transfer has been completed.
        if(strategy.omega != strategy.alpha) {
            collateralManager.reallocateAllNoCollateralCheck(
                transferer,
                _params.thisStrategyID,
                0,
                strategy.basis
            );
        }

        if (_params.alphaTransfer) {
            strategy.alpha = _params.targetUser;
        } else strategy.omega = _params.targetUser;
        
    }

    /**
        @notice Function to perform a combination of two stratgies shared between two users.
        @dev This action can only be performed on two stratgies where the two users are either
        alpha/omega on both strategies, or they are both alpha on one and omega on the other.
        This combination can be performed in one single step and called by anyone, as long as the signatures are correct.
        Note that we do not check collateral requirements here as the strategies are already shared 
        between the same two users.
        @param _params is the input struct for teh function, containing:
            thisStrategyID the ID of one of the two strategies to combine (this strategy
            will be updated to represent the combination of the two)
            targetStrategyID the ID of the other strategy to combine with (this strategy 
            will be deleted)
    */
    function combine(CombineParams calldata _params) external {
        strategiesCompatible(
            _params.sigWeb2,
            _params.thisStrategyID,
            _params.targetStrategyID,
            _params.collateralNonce
        );
        Strategy storage thisStrategy = strategies[_params.thisStrategyID];
        Strategy storage targetStrategy = strategies[_params.targetStrategyID];
        require(
            (thisStrategy.alpha == targetStrategy.alpha &&
                thisStrategy.omega == targetStrategy.omega) ||
                (thisStrategy.alpha == targetStrategy.omega &&
                    thisStrategy.omega == targetStrategy.alpha),
            "S34" // "strategies not shared between two parties"
        );

        //check both alpha & omega have signed, return who signed first
        address initiator = Utils.checkCombineSignatures(
            _params,
            thisStrategy.alpha,
            thisStrategy.omega,
            strategyNonce[_params.thisStrategyID],
            strategyNonce[_params.targetStrategyID],
            collateralManager.collateralNonce()
        )
            ? thisStrategy.alpha
            : thisStrategy.omega;

        address counterparty = initiator == thisStrategy.alpha
            ? thisStrategy.omega
            : thisStrategy.alpha;

        //Increase strategyNonce for remaining strategy
        strategyNonce[_params.thisStrategyID]++;

        // For combinations, the maximum particleMass is taken of the two strategies.
        uint256 particleMass = getParticleMass(
            _params.thisStrategyID,
            ActionType.COMBINATION
        ) > getParticleMass(_params.targetStrategyID, ActionType.COMBINATION)
            ? getParticleMass(_params.thisStrategyID, ActionType.COMBINATION)
            : getParticleMass(_params.targetStrategyID, ActionType.COMBINATION);
        // Lock particle mass for initiator.
        collateralManager.lockParticleMass(
            initiator,
            _params.thisStrategyID,
            thisStrategy.basis,
            particleMass
        );

        // Combine the wavefn's representing the target strategies.
        DecomposedWaveFunction memory decwavefn = Utils.wavefnCombine(
            thisStrategy.phase,
            thisStrategy.amplitude,
            targetStrategy.phase,
            targetStrategy.amplitude,
            thisStrategy.alpha == targetStrategy.omega // Indicates whether the strategies should be "added" or "subtracted".
        );
        bool strategiesCancelOut = (decwavefn.amplitude == 0);

        collateralManager.combineExecute(
            CombineRequest(
                counterparty,
                _params.thisStrategyID,
                _params.targetStrategyID,
                initiator,
                particleMass,
                thisStrategy.basis,
                strategiesCancelOut
            )
        );

        thisStrategy.phase = decwavefn.phase;
        thisStrategy.amplitude = decwavefn.amplitude;
        thisStrategy.maxNotional = decwavefn.maxNotional;

        delete strategies[_params.targetStrategyID]; // Delete targetStrategy.
        delete strategyNonce[_params.targetStrategyID]; //Delete targetStrategy Nonce
        if (strategiesCancelOut) {
            //Strategies cancel out
            delete strategies[_params.thisStrategyID]; // Delete thisStrategy.
            delete strategyNonce[_params.thisStrategyID]; //Delete thisStrategy Nonce
        }
    }

    /**
        @notice Function to initiate a novation of two stratgies shared between three users,
        in order to decrease the overall collateral locked in the system.
        @dev For a novation to be possible both strategies need to have the same phase 
        (i.e.: the same strikes) but can have different amplitudes. 
        Novations can either be complete -if the amplitudes are the same - or partial -if the amplitudes are not the same.
         
        There are 3 scenarios to consider:

        Scenario 1 [Complete Novation]: the amplitude of the 2 stratgies (AB / AC) are the same
        In this case, we remove the strategy BC and redirect the strategy AB to be shared between AC.

        A          C        A --[50]-- C   
         \        /                 
         [50]   [50]   ==>      
          \     /                  
           \   /                  
             B                   B

        Scenario 2 [Partial Novation]: the amplitude of AB is more than the amplitude of BC
        In this case, we redirect the strategy BC to be shared between AC, and decrease the size of AB.
        A          C        A --[30]-- C   
         \        /          \        
         [70]   [30]   ==>   [40]   
          \     /             \     
           \   /               \   
             B                   B

        Scenario 3 [Partial Novation]: the amplitude of AB is less than the amplitude of BC
        In this case, we redirect the strategy AB to be shared between AC, and decrease the size of BC.
        A          C        A --[30]-- C   
         \        /                   /
         [30]   [70]   ==>          [40]
          \     /                   /
           \   /                   /
             B                   B

        The following conventions are used in the code to simplify the handling of the cases.
        The strategy AB is referred to as "thisStrategy" where A is required to be omega, and B to be alpha.
        The strategy BC is referred to as "targetStrategy" where B is required to be omega, and C to be alpha.
        Furthermore, we impose that the newly created strategy between AC will be transferable iff 
        either thisStrategy or targetStrategy are transferable.
        Additionally, we require that the novation is initiated by B.
        @param _params struct containing the parameters (thisStrategyID, targetStrategyID, actionCount1, actionCount2, timestamp)
    */
    function novate(NovateParams calldata _params) external {
        // Verify that the stratgies share a basis and expiry.
        strategiesCompatible(
            _params.sigWeb2,
            _params.thisStrategyID,
            _params.targetStrategyID,
            _params.collateralNonce
        );
        Strategy storage thisStrategy = strategies[_params.thisStrategyID];
        Strategy storage targetStrategy = strategies[_params.targetStrategyID];
        // Verify Params
        Utils.checkNovationSignatures(
            _params,
            thisStrategy.alpha,
            thisStrategy.omega,
            targetStrategy.alpha,
            targetStrategy.omega,
            thisStrategy.transferable,
            targetStrategy.transferable,
            strategyNonce[_params.thisStrategyID],
            strategyNonce[_params.targetStrategyID],
            collateralManager.collateralNonce()
        );

        strategyNonce[_params.thisStrategyID]++;
        strategyNonce[_params.targetStrategyID]++;
        // Verify that the strategies share a phase and amplitude.
        require(
            Utils.wavefnEq(thisStrategy.phase, targetStrategy.phase) &&
                ((thisStrategy.amplitude < 0 && targetStrategy.amplitude < 0) ||
                    (thisStrategy.amplitude > 0 &&
                        targetStrategy.amplitude > 0)),
            "S35"
        ); // "strategies are not compatible"

        // Lock up combination fees.
        uint256 particleMass = getParticleMass(
            _params.thisStrategyID,
            ActionType.NOVATION
        ) > getParticleMass(_params.targetStrategyID, ActionType.NOVATION)
            ? getParticleMass(_params.thisStrategyID, ActionType.NOVATION)
            : getParticleMass(_params.targetStrategyID, ActionType.NOVATION);
        collateralManager.lockParticleMass(
            thisStrategy.alpha,
            _params.thisStrategyID,
            thisStrategy.basis,
            particleMass
        );

        // Get the amplitude of both strategies.
        int256 thisAmplitude = strategies[_params.thisStrategyID].amplitude;
        int256 targetAmplitude = strategies[_params.targetStrategyID].amplitude;
        // Determine transferability of newly created strategy between AC.
        bool newTransferable = strategies[_params.thisStrategyID]
            .transferable || strategies[_params.targetStrategyID].transferable;

        // Novation has been finalised so transfer particle mass
        collateralManager.confiscateCollateral(
            strategies[_params.thisStrategyID].alpha,
            _params.thisStrategyID,
            particleMass,
            strategies[_params.thisStrategyID].basis,
            false
        );

        if (thisAmplitude - targetAmplitude < 0) {
            // Scenario 3 - redirect (alpha) AB to be AC + decrease BC.
            // Rellocate portion of collateral for decreased BC to newly created AC.
            collateralManager.reallocatePortionNoCollateralCheck(
                strategies[_params.targetStrategyID].alpha, // Corresponds to C.
                _params.targetStrategyID, // Corresponds to BC.
                _params.thisStrategyID, // Corresponds to AC.
                thisAmplitude.abs(),
                targetAmplitude.abs(),
                strategies[_params.thisStrategyID].basis
            );
            // Dellocate B's collateral from redirected AB.
            collateralManager.reallocateAllNoCollateralCheck(
                strategies[_params.targetStrategyID].omega, // Corresponds to B.
                _params.thisStrategyID, // Corresponds to AC.
                0,
                strategies[_params.thisStrategyID].basis
            );

            // Update the params of the strategies.
            strategies[_params.thisStrategyID].transferable = newTransferable;
            strategies[_params.thisStrategyID].alpha = strategies[
                _params.targetStrategyID
            ].alpha;

            strategies[_params.targetStrategyID].amplitude =
                targetAmplitude -
                thisAmplitude;
        } else if (thisAmplitude - targetAmplitude > 0) {
            // Scenario 2 - redirect (omega) BC to be AC + decrease AB
            // Rellocate portion of collateral for decreased AB to newly created AC.
            collateralManager.reallocatePortionNoCollateralCheck(
                strategies[_params.thisStrategyID].omega, // Corresponds to A.
                _params.thisStrategyID, // Corresponds to AB.
                _params.targetStrategyID, // Corresponds to AC.
                targetAmplitude.abs(),
                thisAmplitude.abs(),
                strategies[_params.thisStrategyID].basis
            );
            // Dellocate B's collateral from redirected BC.
            collateralManager.reallocateAllNoCollateralCheck(
                strategies[_params.thisStrategyID].alpha, // Corresponds to B.
                _params.targetStrategyID, // Corresponds to AC.
                0,
                strategies[_params.thisStrategyID].basis
            );

            // Update the params of the strategies.
            strategies[_params.targetStrategyID].transferable = newTransferable;
            strategies[_params.targetStrategyID].omega = strategies[
                _params.thisStrategyID
            ].omega;
            strategies[_params.thisStrategyID].amplitude =
                thisAmplitude -
                targetAmplitude;
        } else {
            // Scenario 1 - redirect (alpha) AB to be AC + delete BC.
            // Deallocated B's collateral from both strategies.
            collateralManager.reallocateAllNoCollateralCheck(
                strategies[_params.thisStrategyID].alpha, // Corresponds to B.
                _params.thisStrategyID, // Corresponds to AC.
                0,
                strategies[_params.thisStrategyID].basis
            );
            collateralManager.reallocateAllNoCollateralCheck(
                strategies[_params.thisStrategyID].alpha, // Corresponds to B.
                _params.targetStrategyID, // Corresponds to deleted strategy.
                0,
                strategies[_params.thisStrategyID].basis
            );

            // Reallocate C's collateral to AC.
            collateralManager.reallocateAllNoCollateralCheck(
                strategies[_params.targetStrategyID].alpha, // Corresponds to C.
                _params.targetStrategyID, // Corresponds to deleted strategy.
                _params.thisStrategyID, // Corresponds to AC.
                strategies[_params.thisStrategyID].basis
            );

            // Update the params of the strategies.
            strategies[_params.thisStrategyID].transferable = newTransferable;
            strategies[_params.thisStrategyID].alpha = strategies[
                _params.targetStrategyID
            ].alpha;
            delete strategies[_params.targetStrategyID]; // Delete original BC strategy.
            delete strategyNonce[_params.targetStrategyID]; // Delete strategyNonce for strategy BC
        }
    }

    /************************************************
     *  Option Functionality
     ***********************************************/

    /**
        @notice Function to exercise an expired option.
        @dev Once a strategy has expired the Web2 backend will return alpha and omega payout
        instead of collateral requirements, however, the struct is reused to avoid redundancy.
        To ensure that the sent collateral information is correct (containing payouts instead of collateral requirements), 
        we require that the collateral nonce in the data corresponds to the most recent version 
        (instead of allowing collateral information from the previous checkpoint as with regular collateral information).
        Note that any gains are paid out as soon as the first party calls exercise, however, the strategy is only
        deleted once both parties have exercised for better UX. 
        @param _paramsID struct containing the parameters (strategyID, collateral requirements, collateralNonce)
        @param _signature web2 signature of hashed message
    */
    function exercise(
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature
    ) external {
        // Verify if collateral information provided is valid and sufficiently up-to-date.
        // Note we use the internal helper function to read the strategy params from storage.
        checkCollateralRequirements(_paramsID, _signature);

        uint256 strategyID = _paramsID.strategyID;
        Strategy storage strategy = strategies[strategyID];

        require(
            strategy.expiry <= block.timestamp,
            "S5" // "cannot exercise strategy that has not expired"
        );
        require(
            msg.sender == strategy.alpha || msg.sender == strategy.omega,
            "A21" // "msg.sender not authorised to exercise strategy"
        );

        // If alpha has the payout, omega pays alpha and vice versa.
        // Assume one of them is always zero and one is always the payout.
        // Payout when the first party calls exercise.
        if (strategy.alpha != address(0) && strategy.omega != address(0)) {
            if (_paramsID.alphaCollateralRequirement > 0) {
                collateralManager.relocateCollateral(
                    strategy.omega,
                    strategy.alpha,
                    strategyID,
                    _paramsID.alphaCollateralRequirement,
                    strategy.basis
                );
            } else if (_paramsID.omegaCollateralRequirement > 0) {
                collateralManager.relocateCollateral(
                    strategy.alpha,
                    strategy.omega,
                    strategyID,
                    _paramsID.omegaCollateralRequirement,
                    strategy.basis
                );
            }
        }

        // Deallocate msg.sender's excess collateral.
        collateralManager.reallocateAllNoCollateralCheck(
            msg.sender,
            strategyID,
            0,
            strategy.basis
        );

        // Remove msg.sender from their side.
        if (msg.sender == strategy.alpha) strategy.alpha = address(0);
        else strategy.omega = address(0);

        // Delete strategy once both sides have exercised.
        if (strategy.alpha == address(0) && strategy.omega == address(0)) {
            delete strategies[strategyID];
            delete strategyNonce[strategyID];
        }
    }

    /**
        @dev Trusted liquidate function, where all data is assumed to be correct as it can be only sent by 
        the AdminAddress. Can specify any collateral that should be transferred and confiscated.
        Note it is assumed that one of (_transferredCollateralAlpha, _transferredCollateralOmega) should be zero
        otherwise _transferredCollateralAlpha takes priority.
        @param _cParams the collateralRequirements from web2
        @param _lParams input data (see definition of LiquidateParams)
    */
    function liquidate(
        CollateralParamsFull calldata _cParams,
        LiquidateParams calldata _lParams
    ) external isLiquidator {
        uint256 collateralNonce = collateralManager.collateralNonce();
        //for this function we need a strict equivalent, because we should user LAST collateral requirements;
        require(
            collateralNonce == _cParams.collateralNonce,
            "C34" /*collateralNonce is not the last*/
        );
        Strategy storage strategy = strategies[_lParams._strategyID];
        address alpha = strategy.alpha;
        address omega = strategy.omega;

        Utils.checkWeb2Signature(
            CollateralParamsFull(
                strategy.expiry,
                _cParams.alphaCollateralRequirement,
                _cParams.omegaCollateralRequirement,
                _cParams.collateralNonce,
                strategy.bra,
                strategy.ket,
                strategy.basis,
                _cParams.amplitude,
                _cParams.maxNotional,
                strategy.phase
            ),
            _lParams._sigWeb2,
            collateralManager.collateralNonce(),
            collateralManager.Web2Address()
        );

        bool alphaIsUnderCollaterized = collateralManager.allocatedCollateral(
            alpha,
            _lParams._strategyID
        ) < _cParams.alphaCollateralRequirement;
        bool omegaIsUnderCollaterized = collateralManager.allocatedCollateral(
            omega,
            _lParams._strategyID
        ) < _cParams.omegaCollateralRequirement;

        bool alphaAmountPositive = _lParams._transferredCollateralAlpha +
            _lParams._confiscatedCollateralAlpha >
            0;
        bool omegaAmountPositive = _lParams._transferredCollateralOmega +
            _lParams._confiscatedCollateralOmega >
            0;

        require(alphaAmountPositive || omegaAmountPositive, "C37c"); // At least one amount should be non-zero
        require(
            (!alphaIsUnderCollaterized && !alphaAmountPositive) ||
                (alphaIsUnderCollaterized && alphaAmountPositive),
            "C37a"
        );
        require(
            (!omegaIsUnderCollaterized && !omegaAmountPositive) ||
                (omegaIsUnderCollaterized && omegaAmountPositive),
            "C37b"
        );

        // Update amplitude of the strategy.
        strategy.amplitude = _cParams.amplitude;

        collateralManager.liquidateExecute(
            LiquidateRequest(
                _lParams._strategyID,
                alpha,
                omega,
                _lParams._transferredCollateralAlpha,
                _lParams._transferredCollateralOmega,
                _lParams._confiscatedCollateralAlpha,
                _lParams._confiscatedCollateralOmega,
                strategy.basis,
                alphaIsUnderCollaterized &&
                    (_lParams._confiscatedCollateralAlpha > 0),
                omegaIsUnderCollaterized &&
                    (_lParams._confiscatedCollateralOmega > 0)
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

enum ActionType {
    NONE,
    CLAIM,
    TRANSFER,
    COMBINATION,
    NOVATION
}

struct Strategy {
    bool transferable;
    address bra; // LHS of underlying currency pair
    address ket; // RHS of underlying currency pair
    address basis; // accounting currency
    address alpha;
    address omega;
    uint256 expiry; // 0 is reserved
    int256 amplitude;
    uint256 maxNotional;
    int256[2][] phase;
}

struct CollateralLock {
    uint256 amount;
    uint256 lockExpiry;
}

struct CollateralParamsFull {
    uint256 expiry;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 collateralNonce;
    address bra;
    address ket;
    address basis;
    int256 amplitude;
    uint256 maxNotional;
    int256[2][] phase;
}

struct CollateralParamsID {
    uint256 strategyID;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 collateralNonce;
}

struct ReallocateCollateralRequest {
    address sender;
    address alpha;
    address omega;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    uint256 fromStrategyID;
    uint256 toStrategyID;
    uint256 amount;
    address basis;
}

struct PeppermintRequest {
    address sender;
    uint256 strategyID;
    address alpha;
    address omega;
    uint256 alphaCollateralRequired;
    uint256 omegaCollateralRequired;
    address basis;
    int256 premium;
    uint256 particleMass;
}

struct CollateralLockRequest {
    address sender1;
    address sender2;
    uint256 strategyID;
    uint256 particleMass;
    address alpha;
    address omega;
    int256 premium;
    uint256 alphaCollateralRequirement;
    uint256 omegaCollateralRequirement;
    address basis;
    bool isAlpha;
    bool isTransfer;
}

struct CombineRequest {
    address sender;
    uint256 thisStrategyID;
    uint256 targetStrategyID;
    address initiator;
    uint256 particleMass;
    address basis;
    bool strategiesCancelOut;
}

struct LiquidateParams {
    bytes _sigWeb2;
    uint256 _strategyID;
    uint256 _transferredCollateralAlpha;
    uint256 _transferredCollateralOmega;
    uint256 _confiscatedCollateralAlpha;
    uint256 _confiscatedCollateralOmega;
}

struct LiquidateRequest {
    uint256 strategyID;
    address alpha;
    address omega;
    uint256 transferredCollateralAlpha;
    uint256 transferredCollateralOmega;
    uint256 confiscatedCollateralAlpha;
    uint256 confiscatedCollateralOmega;
    address basis;
    bool confiscateAlpha;
    bool confiscateOmega;
}

struct NovateParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    bytes sig3;
    uint256 thisStrategyID;
    uint256 targetStrategyID;
    uint256 thisStrategyNonce;
    uint256 targetStrategyNonce;
    uint256 collateralNonce;
}

struct CombineParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    uint256 thisStrategyID;
    uint256 targetStrategyID;
    uint256 thisStrategyNonce;
    uint256 targetStrategyNonce;
    uint256 collateralNonce;
}

struct TransferParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    bytes sig3;
    uint256 thisStrategyID;
    address targetUser;
    uint256 strategyNonce;
    int256 premium;
    bool alphaTransfer;
}

struct SpearmintParams {
    bytes sigWeb2;
    bytes sig1;
    bytes sig2;
    address alpha;
    address omega;
    int256 premium;
    bool transferable;
    uint256 pairNonce;
}

struct DecomposedWaveFunction {
    int256[2][] phase;
    int256 amplitude;
    uint256 maxNotional;
}
// TODO: might want to move all smaller-than-256-bit types to end of structs.
// as long as they're together, though, shouldn't be much of a problem
// more of a convention thing?

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
    @title Utils provides methods for taking care of integer arithmetic, wavefunction operations, type conversion, and cryptographic signature checks.
    @dev Additional documentation can be found on notion
    @ https://www.notion.so/trufin/V2-Documentation-6a7a43f8b577411d84277fc543f99063?d=63b28d74feba48c6be7312709a31dbe9#5bff636f9d784712af5de7df0a19ea72
*/
library Utils {
    /************************************************
     *  Helpers Functions
     ***********************************************/

    /**
        @notice Math util function to get the absolute value of an integer
        @param a integer to find the abs value of
    */
    function abs(int256 a) public pure returns (uint256) {
        return (a >= 0) ? uint256(a) : uint256(-a);
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
        @notice Math util function to get the greatest common divisor (GCD) of two unsigned integers
        @param a the first unsigned integer (order not important)
        @param b the second unsigned integer (order not important)
    */
    function gcd(uint256 a, uint256 b) public pure returns (uint256) {
        while (b != 0) (a, b) = (b, a % b);
        return a;
    }

    /**
        @notice Type util function to convert an integer to a string
        @param a the integer
        @return output the string
    */
    function intToString(int256 a) public pure returns (string memory) {
        return string.concat((a < 0) ? "-" : "", Strings.toString(abs(a)));
    }

    /************************************************
     *  Wavefunction Operators
     ***********************************************/

    /**
        @notice Wavefn util function to get the greatest common divisor (GCD) of the notionals in a wavefunction (denoted in Finneys)
        @param _wavefn the wavefunction of which to find the GCD
    */
    function wavefnGCD(int256[2][] memory _wavefn)
        public
        pure
        returns (uint256)
    {
        uint256 cur_gcd = abs(_wavefn[0][0]);
        for (uint256 i = 1; i < _wavefn.length; ) {
            cur_gcd = gcd(cur_gcd, abs(_wavefn[i][0]));
            unchecked {
                i++;
            }
        }
        return cur_gcd;
    }

    /**
        @notice Wavefn util function to decompose a wavefunction into its phase and amplitude
        @dev The amplitude is the GCD of the wavefn notionals and the phase is a wavefn's fingerprint,
        a deterministic unique identifier of the wavefn's optionality.
        @dev The phase is the wavefn with the notionals divided through by the GCD and where the first notional value is always positive.
        @dev The amplitude is the GCD of the wavefn notionals, made negative if the first wavefn notional is negative (thus making the
        first phase notional always positive).
        @param _wavefn the wavefunction to normalise
        @return _decwavefn the decomposed wave function
    */
    function wavefnNormalise(int256[2][] memory _wavefn)
        public
        pure
        returns (DecomposedWaveFunction memory)
    {
        if (_wavefn.length == 0) return DecomposedWaveFunction(_wavefn, 0, 0);

        // require wavefn to be sorted first by strike, next by amount
        for (uint256 i = 1; i < _wavefn.length; ) {
            require(
                _wavefn[i - 1][1] < _wavefn[i][1] ||
                    (_wavefn[i - 1][1] == _wavefn[i][1] &&
                        _wavefn[i - 1][0] <= _wavefn[i][0]),
                "Wave function must be sorted first my strike, next by amount"
            );
            require(_wavefn[i][0] != 0, "Wave function cannot contain zero");
            unchecked {
                i++;
            }
        }

        // calculate amplitude (GCD), make it negative if the first strike is negative
        // therefore, the first ratio value will always be positive and the ratio will
        // always be in its simplest form (phase)
        // alpha will always be long the first strike in the list
        DecomposedWaveFunction memory _decwavefn;
        _decwavefn.amplitude =
            int256(wavefnGCD(_wavefn)) *
            (_wavefn[0][0] < 0 ? -1 : int8(1));

        _decwavefn.maxNotional = 0;
        _decwavefn.phase = _wavefn;
        for (uint256 i = 0; i < _wavefn.length; ) {
            _decwavefn.phase[i][0] /= int256(_decwavefn.amplitude);
            _decwavefn.maxNotional = abs(_decwavefn.phase[i][0]) >
                _decwavefn.maxNotional
                ? abs(_decwavefn.phase[i][0])
                : _decwavefn.maxNotional;
            unchecked {
                i++;
            }
        }

        return _decwavefn;
    }

    /**
        @notice Wavefn util function to perform the inverse of Utils function wavefnNormalise: given a phase and amplitude, combine them
        into a wavefunction.
        @dev Wavefn notionals calculated by multiplying through phase notionals by amplitude. Wavefn strikes are the same as the phase strikes.
        @param _phase the phase of the wavefn
        @param _amplitude the amplitude of the wavefn
        @return wavefn the wavefn made up of the inputted phase and amplitude
    */
    function wavefnDenormalise(int256[2][] calldata _phase, int256 _amplitude)
        external
        pure
        returns (int256[2][] memory)
    {
        int256[2][] memory wavefn = new int256[2][](_phase.length);

        for (uint256 i = 0; i < _phase.length; ) {
            wavefn[i][0] = _phase[i][0] * _amplitude;
            wavefn[i][1] = _phase[i][1];
            unchecked {
                i++;
            }
        }

        return wavefn;
    }

    /**
        @notice Wavefn util function to combine two wavefunctions into one sorted wavefunction, cancelling out or adding any overlapping notionals.
        @param _phase1 the first wavefn (order not important)
        @param _amplitude1 .
        @param _phase2 the second wavefn (order not important)
        @param _amplitude2 .
        @param _opposite true if both wavefns have the same alpha, false if one wavefn's alpha is the other's omega
        @return _decwavefn Decomposed Wave Function
    */
    // Order: (amplitude, maxNotional, phase)
    // Add a check that the resulting wavefn len isn't greater than 8
    function wavefnCombine(
        int256[2][] calldata _phase1,
        int256 _amplitude1,
        int256[2][] calldata _phase2,
        int256 _amplitude2,
        bool _opposite
    ) external pure returns (DecomposedWaveFunction memory) {
        _amplitude2 *= _opposite ? -1 : int8(1);
        uint8[3] memory pointers;
        int256[2][] memory tmpWavefn = new int256[2][](
            _phase1.length + _phase2.length
        );

        while (pointers[0] + pointers[1] < _phase1.length + _phase2.length) {
            if (
                pointers[1] == _phase2.length ||
                (pointers[0] < _phase1.length &&
                    _phase1[pointers[0]][1] < _phase2[pointers[1]][1])
            ) {
                tmpWavefn[pointers[2]] = [
                    _phase1[pointers[0]][0] * _amplitude1,
                    _phase1[pointers[0]][1]
                ];

                unchecked {
                    pointers[0]++;
                    pointers[2]++;
                }
            } else if (
                pointers[0] == _phase1.length ||
                (pointers[1] < _phase2.length &&
                    _phase2[pointers[1]][1] < _phase1[pointers[0]][1])
            ) {
                tmpWavefn[pointers[2]] = [
                    _phase2[pointers[1]][0] * _amplitude2,
                    _phase2[pointers[1]][1]
                ];

                unchecked {
                    pointers[1]++;
                    pointers[2]++;
                }
            } else {
                int256 notional = _phase1[pointers[0]][0] *
                    _amplitude1 +
                    _phase2[pointers[1]][0] *
                    _amplitude2;

                if (notional != 0) {
                    tmpWavefn[pointers[2]] = [
                        notional,
                        _phase1[pointers[0]][1]
                    ];
                    unchecked {
                        pointers[2]++;
                    }
                }

                unchecked {
                    pointers[0]++;
                    pointers[1]++;
                }
            }
        }

        int256[2][] memory resultWavefn = new int256[2][](pointers[2]);
        for (uint256 i = 0; i < pointers[2]; ) {
            resultWavefn[i] = tmpWavefn[i];

            unchecked {
                i++;
            }
        }

        return wavefnNormalise(resultWavefn);
    }

    /**
        @notice Wavefn util function to return whether two wavefns are identical.
        @dev This only returns true if all parameters are EXACTLY the same.
        @param _wavefn1 the first wavefn (order not important)
        @param _wavefn2 the second wavefn (order not important)
        @return equal boolean: true if wavefns are identical, false if not.
    */
    function wavefnEq(
        int256[2][] calldata _wavefn1,
        int256[2][] calldata _wavefn2
    ) external pure returns (bool) {
        if (_wavefn1.length != _wavefn2.length) return false;

        for (uint256 i = 0; i < _wavefn1.length; ) {
            if (
                _wavefn1[i][0] != _wavefn2[i][0] ||
                _wavefn1[i][1] != _wavefn2[i][1]
            ) return false;
            unchecked {
                i++;
            }
        }

        return true;
    }

    /**
        @notice Phase util function to calculate the maximum from the list of notionals.
        @param _phase the phase to find the max notional of
        @return maxNotional the max notional
    */
    function getMaxNotional(int256[2][] calldata _phase)
        external
        pure
        returns (uint256)
    {
        uint256 maxNotional;

        for (uint256 i = 0; i < _phase.length; ) {
            uint256 unsigned = abs(_phase[i][0]);
            if (unsigned > maxNotional) {
                maxNotional = unsigned;
            }

            unchecked {
                i++;
            }
        }

        return maxNotional;
    }

    /************************************************
     *  Cryptographic Collateral Verification
     ************************************************

    /**
        @notice Cryptography util fn returns whether the signature produced in signing a hash was signed
        by the private key corresponding to the inputted public address
        @param _hashedMessage the hashed message
        @param _signature the signature produced in signing the hashed message
        @param _signerAddress the public address
        @return signer_valid true if _signerAddress's corresponding private key signed _hashedMessage to
        produce _signature, false in any other case
    */
    function isValidSigner(
        bytes32 _hashedMessage,
        bytes memory _signature,
        address _signerAddress
    ) public view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashedMessage)
        );
        return
            SignatureChecker.isValidSignatureNow(
                _signerAddress,
                prefixedHashMessage,
                _signature
            );
    }

    function checkWeb2Signature(
        CollateralParamsFull calldata _cParams,
        bytes calldata _sigWeb2,
        uint256 _collateralNonce,
        address web2Address
    ) external view {
        //check collateralNonce is correct
        require(
            (_collateralNonce >= _cParams.collateralNonce) &&
                (_collateralNonce - _cParams.collateralNonce <= 1),
            "C31"
        ); // "errors with collateral requirement"

        //Msg that should be signed with SignatureWeb2
        bytes32 msgHash = keccak256(
            abi.encode(
                _cParams.expiry,
                _cParams.alphaCollateralRequirement,
                _cParams.omegaCollateralRequirement,
                _cParams.collateralNonce,
                _cParams.bra,
                _cParams.ket,
                _cParams.basis,
                _cParams.amplitude,
                _cParams.maxNotional,
                _cParams.phase
            )
        );
        require(isValidSigner(msgHash, _sigWeb2, web2Address), "A28"); //Not signed by Web2 Collateral Manager
    }

    function checkWebSignatureForNonce(
        bytes calldata _web2Sig,
        uint256 _collateralNonce,
        address _web2Address
    ) external view {
        bytes32 msgHash = keccak256(abi.encode(_collateralNonce));
        require(isValidSigner(msgHash, _web2Sig, _web2Address), "A28"); //Not signed by Web2 Collateral Manager
    }

    function checkWeb2SignatureForExpiry(
        bytes calldata _sigWeb2,
        address _web2Address,
        uint256 _paramsNonce,
        uint256 _expiry
    ) external view {
        //Msg that should be signed with SignatureWeb2
        bytes32 msgHash = keccak256(abi.encode(_expiry, _paramsNonce, true));
        require(isValidSigner(msgHash, _sigWeb2, _web2Address), "S1"); // Strategy is expired
    }

    /************************************************
     *  Cryptographic Novation Verification
     ***********************************************/

    /**
        @notice Cryptography util fn returns whether the signature produced in signing a hash was signed
        by the private key corresponding to the inputted public address
        @param _params struct containing the parameters (thisStrategyID, targetStrategyID, actionCount1, actionCount2, timestamp)
        @param _thisStrategyNonce nonce for thisStrategy i.e., first strategy
        @param _targetStrategyNonce nonce for targetStrategy i.e., second strategy
        produce _signature, false in any other case
    */
    function checkNovationSignatures(
        NovateParams calldata _params,
        address _thisStrategyAlpha,
        address _thisStrategyOmega,
        address _targetStrategyAlpha,
        address _targetStrategyOmega,
        bool _thisStrategyTransferable,
        bool _targetStrategyTransferable,
        uint256 _thisStrategyNonce,
        uint256 _targetStrategyNonce,
        uint256 _collateralNonce
    ) external view {
        require(
            (_collateralNonce >= _params.collateralNonce) &&
                (_collateralNonce - _params.collateralNonce <= 1),
            "A26" // "Signature is expired"
        );
        require(
            _params.thisStrategyNonce == _thisStrategyNonce &&
                _params.targetStrategyNonce == _targetStrategyNonce,
            "A27" //Strategy Nonce invalid
        );
        require(_thisStrategyAlpha == _targetStrategyOmega, "A32");

        bytes32 calculatedHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetStrategyID,
                _thisStrategyNonce,
                _targetStrategyNonce,
                _params.collateralNonce,
                "novate"
            )
        );

        // Case 1 (Mandatory): Needed signature from initiator (_thisStrategyAlpha || _targetStrategyOmega)
        require(
            isValidSigner(calculatedHash, _params.sig1, _thisStrategyAlpha),
            "A29"
        ); // "First signer must be alpha on first and omega on second strategy"
        // Case 2: If strategy1 is transferable and strategy2 isn't we only need signature from middle person and second strategy alpha
        if (_thisStrategyTransferable && !_targetStrategyTransferable) {
            require(
                isValidSigner(
                    calculatedHash,
                    _params.sig3,
                    _targetStrategyAlpha
                ),
                "A29-a"
            ); // Signature needed from target strategy alpha
        }
        // Case 3: If strategy1 is non-transferable and strategy2 is then we only need signature from middle person and first strategy omega
        else if (!_thisStrategyTransferable && _targetStrategyTransferable) {
            require(
                isValidSigner(calculatedHash, _params.sig2, _thisStrategyOmega),
                "A29-b"
            ); // Signature needed from this strategy omega
        }
        // Case 4: If both strategies are non-transferable we need everybody's signature
        else if (!_thisStrategyTransferable && !_targetStrategyTransferable) {
            require(
                isValidSigner(
                    calculatedHash,
                    _params.sig2,
                    _thisStrategyOmega
                ) &&
                    isValidSigner(
                        calculatedHash,
                        _params.sig3,
                        _targetStrategyAlpha
                    ),
                "A29-c" // "Signature needed by this strategy omega and target strategy alpha"
            );
        }
    }

    function checkCombineSignatures(
        CombineParams calldata _params,
        address _alpha,
        address _omega,
        uint256 _thisStrategyNonce,
        uint256 _targetStrategyNonce,
        uint256 _collateralNonce
    )
        external
        view
        returns (
            bool //initiator isAlpha
        )
    {
        //check less than 2 epoch has passed since first signature

        require(
            (_collateralNonce >= _params.collateralNonce) &&
                (_collateralNonce - _params.collateralNonce <= 1),
            "A26"
        ); //Signature is expired

        require(
            _params.thisStrategyNonce == _thisStrategyNonce &&
                _params.targetStrategyNonce == _targetStrategyNonce,
            "A27" //Strategy Nonce invalid
        );

        //Msg that should be signed with Signature2
        bytes32 msgHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetStrategyID,
                _thisStrategyNonce,
                _targetStrategyNonce,
                _params.collateralNonce,
                "combine"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _params.sig2, _alpha);
        require(isAlpha || isValidSigner(msgHash, _params.sig2, _omega), "A23"); //Signature2 not signed by alpha or by omega

        if (isAlpha) {
            require(isValidSigner(msgHash, _params.sig1, _omega), "A24"); //Signature2 signed by alpha, Signature1 not signed by omega
            return false;
        } else {
            require(isValidSigner(msgHash, _params.sig1, _alpha), "A25"); //Signature2 signed by omega, Signature1 not signed by alpha
            return true;
        }
    }

    function checkSpearmintUserSignatures(
        SpearmintParams calldata _aParams,
        uint256 _pairNonce
    ) external view {
        //Msg that should be signed with Signature2
        bytes32 msgHash = keccak256(
            abi.encode(
                _aParams.alpha,
                _aParams.omega,
                _aParams.transferable,
                _aParams.premium,
                _pairNonce,
                _aParams.sigWeb2,
                "spearmint"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _aParams.sig2, _aParams.alpha);
        require(
            isAlpha || isValidSigner(msgHash, _aParams.sig2, _aParams.omega),
            "A23"
        ); //Signature2 not signed by alpha or by omega

        if (isAlpha) {
            require(
                isValidSigner(msgHash, _aParams.sig1, _aParams.omega),
                "A24"
            ); //Signature2 signed by alpha, Signature1 not signed by omega
        } else {
            require(
                isValidSigner(msgHash, _aParams.sig1, _aParams.alpha),
                "A25"
            ); //Signature2 signed by omega, Signature1 not signed by alpha
        }
    }

    function checkTransferUserSignatures(
        TransferParams calldata _params,
        address _alpha,
        address _omega,
        uint256 _strategyNonce,
        bool transferable
    ) external view {
        require(_params.strategyNonce == _strategyNonce, "A27"); //Strategy Nonce invalid

        // alpha / omega signs message that yes i want to transfer my position to target - sig1
        // target signs message that yes i agree to enter the position - sig2 using sig1
        // omega / alpha signs that they agree to the position. - sig3 using sig1

        bytes32 msgHash = keccak256(
            abi.encode(
                _params.thisStrategyID,
                _params.targetUser,
                _strategyNonce,
                _params.premium,
                _params.alphaTransfer,
                _params.sigWeb2,
                "transfer"
            )
        );

        bool isAlpha = isValidSigner(msgHash, _params.sig1, _alpha);
        require(isAlpha || isValidSigner(msgHash, _params.sig1, _omega), "A23"); //Signature not signed by alpha or by omega

        require(
            isValidSigner(msgHash, _params.sig2, _params.targetUser),
            "A30"
        );

        if (transferable) {
            return;
        }

        if (isAlpha) {
            require(isValidSigner(msgHash, _params.sig3, _omega), "A24");
        } else {
            require(isValidSigner(msgHash, _params.sig3, _alpha), "A25");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import {Strategy, ActionType} from "../misc/Types.sol";
import {CollateralManager} from "./CollateralManager.sol";

abstract contract TFMStorage {
    /**
        @notice Stores collateral manager contract, used to post / withdraw / allocate / lock collateral
        and verify collateral requirements
    */
    CollateralManager public collateralManager;

    /**
        @notice Map strategy ids to strategy structs.
    */
    mapping(uint256 => Strategy) public strategies;

    /**
        @notice Map ERC20 addresses to price of $10.
    */
    mapping(address => uint256) public photons;

    /**
        @notice Tracks most recent strategy id minted.
    */
    uint256 public strategyCounter;

    /**
        @notice Defines Liquidator of the contract for liquidations.
    */
    address public LiquidatorAddress;

    /**
        @dev Fees in basis points of maxNotional * amplitude (divide by 10_000 to get fraction).
    */
    mapping(ActionType => uint256) public particles;

    /**
        @dev Maps Strategy IDs to the actions they have completed (nonce)
    */
    mapping(uint256 => uint256) public strategyNonce;

    /// @notice to store user pair counter
    mapping(address => mapping(address => uint256)) internal userPairCounter;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {PersonalPool} from "./PersonalPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Utils} from "../libraries/Utils.sol";
import {CollateralManagerStorage} from "./CollateralManagerStorage.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ICollateralManager} from "../interfaces/ICollateralManager.sol";
import {TFM} from "./TFM.sol";

/**
    @title Collateral Manager contract called by TFM to deal with posting/withdrawing, allocating/reallocating, locking/unlocking of collateral.
    @notice Used only by TFM (which forwards collateral management calls from users) for:
    * Posting/withdrawing - this is for users to increase or decrease their unallocated collateral (stored in the unallocatedCollateral mapping)
    * Allocating/reallocating - this is for users to increase or decrease their collateral allocated to a given strategy (stored in the
    allocatedCollateral mapping)
    * Locking/unlocking - this is for trusted lockers to increase or decrease a user's locked collateral (stored in the lockedCollateral mapping)
    used in the TFM `peppermint` function.
    @dev Additional documentation can be found on notion
    @ https://www.notion.so/trufin/V2-Documentation-6a7a43f8b577411d84277fc543f99063?d=63b28d74feba48c6be7312709a31dbe9#5bff636f9d784712af5de7df0a19ea72
*/
contract CollateralManager is
    CollateralManagerStorage,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ICollateralManager
{
    using SafeERC20 for IERC20;
    using Utils for int256;

    constructor() {
        _disableInitializers();
    }

    /**
        @notice Set constants and special addresses.
        @param _owner the owner address, which can set addresses
        @param _TreasuryAddress the treasury address, to which non-liquidation fees are sent
        @param _InsuranceFundAddress the treasury address, to which liquidation fees are sent
        @param _Web2Address the collateral message hash signer
    */
    function initialize(
        address _owner,
        address _TreasuryAddress,
        address _InsuranceFundAddress,
        address _Web2Address,
        address _RelayAddress
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(_owner);
        TreasuryAddress = _TreasuryAddress;
        InsuranceFundAddress = _InsuranceFundAddress;
        Web2Address = _Web2Address;
        RelayAddress = _RelayAddress;
        personalPools[TreasuryAddress] = address(new PersonalPool());
        personalPools[_InsuranceFundAddress] = address(new PersonalPool());
    }

    /************************************************
     *  Modifiers & Setters
     ***********************************************/

    /**
        @notice Modifier to only allow TFM transactions.
    */
    modifier isTFM() {
        require(msg.sender == TFMAddress, "A4");
        _;
    }

    /**
        @notice Modifier to only allow Relay transactions.
    */
    modifier isRelay() {
        require(msg.sender == RelayAddress, "A5");
        _;
    }

    /**
        @notice Function for admin to set the TFM address.
        @param _TFMAddress the TFM contract address
    */
    function setTFMAddress(address _TFMAddress) external onlyOwner {
        TFMAddress = _TFMAddress;
    }

    /**
        @notice Function for admin to set web2 address
        @param _Web2Address the web2 address (public address which signs collateral message hashes)
    */
    function setWeb2Address(address _Web2Address) external onlyOwner {
        Web2Address = _Web2Address;
    }

    /**
        @notice Setter for RelayAddress.
        @param _RelayAddress the new RelayAddress
    */
    function setRelayAddress(address _RelayAddress) external onlyOwner {
        RelayAddress = _RelayAddress;
    }

    /**
        @notice Function for admin to set the TFM address.
        @param _TreasuryAddress the TFM contract address
    */
    function setTreasuryddress(address _TreasuryAddress) external onlyOwner {
        TreasuryAddress = _TreasuryAddress;
    }

    /**
        @notice Function for admin to set web2 address
        @param _InsuranceFundAddress the web2 address (public address which signs collateral message hashes)
    */
    function setInsuranceFundAddress(address _InsuranceFundAddress)
        external
        onlyOwner
    {
        InsuranceFundAddress = _InsuranceFundAddress;
    }

    /************************************************
     *  TFM Helpers
     ***********************************************/

    /**
        @notice Function to forcibly relocate a given amount of allocated collateral to the treasury's personal pool,
        used in liquidations.
        @param _user user from which to confiscate collateral
        @param _strategyID strategy which the user has collateral allocated to
        @param _amount amount to confiscate
        @param _basis basis of confiscated collateral
    */
    function confiscateCollateral(
        address _user,
        uint256 _strategyID,
        uint256 _amount,
        address _basis,
        bool _liquidation
    ) public isTFM {
        require(allocatedCollateral[_user][_strategyID] >= _amount, "C17");

        relocateCollateral(
            _user,
            _liquidation ? InsuranceFundAddress : TreasuryAddress,
            _strategyID,
            _amount,
            _basis
        );
        reallocateAllNoCollateralCheck(
            _liquidation ? InsuranceFundAddress : TreasuryAddress,
            _strategyID,
            0,
            _basis
        );
    }

    /************************************************
     *  Basic Personal Pool Functions
     ***********************************************/
    /**
        @dev Function to get the existing, or create a new personal pool for a given user.
        @param _user the address of the user to getOrCreate the personal pool for
        @return address of the personal pool corresponding to the user
    */
    function _getOrCreatePersonalPool(address _user)
        internal
        returns (address)
    {
        address personalPool = personalPools[_user];
        if (personalPool == address(0)) {
            personalPool = address(new PersonalPool());
            personalPools[_user] = personalPool;
        }
        return personalPool;
    }

    /**
        @notice Function for a user to increase their unallocated collateral by moving funds into their personal pool.
        @param _basis basis of collateral posted
        @param _amount amount of collateral posted
    */
    function post(address _basis, uint256 _amount) external {
        address personalPool = _getOrCreatePersonalPool(msg.sender);
        IERC20(_basis).safeTransferFrom(msg.sender, personalPool, _amount);
        unallocatedCollateral[msg.sender][_basis] += _amount;
    }

    /**
        @notice Function for a user to decrease their unallocated collateral by moving funds out of their personal pool.
        @param _basisAddress basis address of collateral withdrawn
        @param _amount amount of collateral withdrawn
    */
    function withdraw(address _basisAddress, uint256 _amount) external {
        uint256 fee = TFM(TFMAddress).photons(_basisAddress);
        require(
            _amount + fee <= unallocatedCollateral[msg.sender][_basisAddress],
            "C11" // "amount greater than unallocated collateral"
        );
        unallocatedCollateral[msg.sender][_basisAddress] -= _amount + fee;
        unallocatedCollateral[TreasuryAddress][_basisAddress] += fee;

        address personalPool = personalPools[msg.sender];
        address treasuryPool = _getOrCreatePersonalPool(TreasuryAddress);

        // send fees to Treasury address
        PersonalPool(personalPool).approve(_basisAddress, fee);
        IERC20(_basisAddress).safeTransferFrom(personalPool, treasuryPool, fee);

        PersonalPool(personalPool).approve(_basisAddress, _amount);
        IERC20(_basisAddress).safeTransferFrom(
            personalPool,
            msg.sender,
            _amount
        );
    }

    /************************************************
     *  Cryptographic Collateral Verification
     ***********************************************/

    /**
        @notice Function to increase the global collateral nonce by one (in case of normal update) or two (in case of
        emergency update).
        @dev As a collateral signature is valid if its nonce is equal or one less than the global nonce, an increase
        of two of global nonce in the case of an emergency is necessary to invalidate any existing collateral signatures.
        @param _web2Sig Signature from collateral manager web2Address
        @param _collateralNonce latest nonce
    */
    function updateCollateralNonce(
        bytes calldata _web2Sig,
        uint256 _collateralNonce
    ) external {
        require(_collateralNonce > collateralNonce, "C32");
        Utils.checkWebSignatureForNonce(
            _web2Sig,
            _collateralNonce,
            Web2Address
        );
        collateralNonce = _collateralNonce;
    }

    /************************************************
     *  Collateral Locking
     ***********************************************/

    /**
        @notice Function to change whether a locker is trusted or not. 
        @dev a user's lockers can set collateralLocks on their unallocated collateral and use it in
        minting strategies on their behalf (using the TFM `peppermint` function)
        @param _locker address of locker to modify
        @param _trusted true to change the inputted _locker address to a trusted locker, false to
        remove it as a trusted locker
    */
    function changeTrustedLocker(address _locker, bool _trusted) external {
        trustedLockers[msg.sender][_locker] = _trusted;
    }

    /**
        @notice Function for a locker to increase a user's locked collateral (by setting or modifying a collateralLock).
        @param _user address of user getting locked
        @param _basis basis of the collateral lock
        @param _amount amount being locked
        @param _lockExpiry expiry of lock; this is when the user can call `unlockCollateral` to move the locked collateral
        back into their unallocated collateral pool
    */
    function increaseLockedCollateral(
        address _user,
        address _basis,
        uint256 _amount,
        uint256 _lockExpiry
    ) external {
        require(
            trustedLockers[_user][msg.sender],
            "A31" // "msg.sender is not a trusted locker for user"
        );
        require(
            unallocatedCollateral[_user][_basis] >= _amount,
            "C11" // "user does not have enough unallocated collateral"
        );

        CollateralLock memory cl = lockedCollateral[_user][msg.sender][_basis];
        uint256 newLockExpiry = (cl.lockExpiry >= _lockExpiry)
            ? cl.lockExpiry
            : _lockExpiry;

        unallocatedCollateral[_user][_basis] -= _amount;
        lockedCollateral[_user][msg.sender][_basis] = CollateralLock(
            cl.amount + _amount,
            newLockExpiry
        );
    }

    // @param _sender sender requesting to unlock collateral
    /**
        @notice Function for a locker to move collateral from a collateral lock to the user's unallocated collateral.
        If the collateral lock has already expired, this the user can also call `unlockCollateral`.
        @param _user user to unlock collateral of
        @param _locker locker to which locked collateral is assigned to in lockedCollateral mapping
        @param _basis basis of locked collateral
        @param _amount amount of collateral to unlock (what to reduce collateral lock's amount by)
    */
    function unlockCollateral(
        address _user,
        address _locker,
        address _basis,
        uint256 _amount
    ) external {
        _unlockCollateral(msg.sender, _user, _locker, _basis, _amount);
    }

    function _unlockCollateral(
        address _sender,
        address _user,
        address _locker,
        address _basis,
        uint256 _amount
    ) internal {
        CollateralLock memory cl = lockedCollateral[_user][_locker][_basis];

        if (_sender == _user) {
            require(
                cl.lockExpiry <= block.timestamp,
                "C41" // "collateral lock has not yet expired"
            );
            require(
                cl.amount >= _amount,
                "C42" // "amount larger than locked amount"
            );
            lockedCollateral[_user][_locker][_basis] = CollateralLock(
                cl.amount - _amount,
                cl.lockExpiry
            );
            unallocatedCollateral[_user][_basis] += _amount;
        } else {
            require(
                _sender == _locker,
                "A31" // "not authorised"
            );
            require(
                cl.amount >= _amount,
                "C42" // "amount larger than locked amount"
            );

            lockedCollateral[_user][_locker][_basis] = CollateralLock(
                cl.amount - _amount,
                cl.lockExpiry
            );
            unallocatedCollateral[_user][_basis] += _amount;
        }
    }

    /************************************************
     *  Collateral Allocation & Reallocation
     ***********************************************/

    /**
        @notice Function to lock the amount corresponding to particleMass.
        @dev We expect particleMass to be relatively small, so this function checks if
        the user has already allocated enough collateral to the strategy to cover this amount,
        or we additonally try to allocate sufficient funds from the unallocated pool.
        @param _user address of user to lock particleMass for
        @param _strategyID ID of strategy to check the allocation for / lock the funds to
        @param _basis the address of the ERC20 token used to collateralise the given strategy
        @param _particleMass the amount of the ERC20 token to lock
    */
    function lockParticleMass(
        address _user,
        uint256 _strategyID,
        address _basis,
        uint256 _particleMass
    ) public isTFM {
        require(
            allocatedCollateral[_user][_strategyID] +
                unallocatedCollateral[_user][_basis] >=
                _particleMass,
            "C13"
        );
        if (allocatedCollateral[_user][_strategyID] < _particleMass) {
            _allocateCollateralUser(
                _user,
                _strategyID,
                _particleMass - allocatedCollateral[_user][_strategyID],
                _basis
            );
        }
    }

    /**
        @notice Function to allocate collateral from a user's unallocated collateral to a strategy id
        @param _toStrategyID strategy id where the collateral is being allocated
        @param _amount amount to allocate
    */
    function allocateCollateral(uint256 _toStrategyID, uint256 _amount)
        external
    {
        address basis;
        (, , , basis, , , , , ) = TFM(TFMAddress).strategies(_toStrategyID);
        _allocateCollateralUser(msg.sender, _toStrategyID, _amount, basis);
    }

    /**
        @dev Function to perform collateral allocation from unallocated collateral w/o 
        checking requirements.
        @param _user address of user to allocate collateral for
        @param _toStrategyID ID of strategy to allocate collateral to
        @param _amount amount of ERC20 token to allocate
        @param _basis address of ERC20 token used to collateralise
    */
    function _allocateCollateralUser(
        address _user,
        uint256 _toStrategyID,
        uint256 _amount,
        address _basis
    ) private {
        require(
            _basis != address(0),
            "S2" // strategy should exist
        );
        require(
            unallocatedCollateral[_user][_basis] >= _amount,
            "C11" // "not enough unallocated collateral"
        );
        return
            _reallocateNoCollateralCheck(
                _user,
                0,
                _toStrategyID,
                _amount,
                _basis
            );
    }

    /**
        @notice Function called by TFM to reallocate collateral from a strategy to another strategy
        or to the unallocated pool.
        @dev Diagram illustrating a relocation:

           +--------------+
          /|             /|
         / |            / |                                   
        *--+-----------*  |                                   
        |  |   User    |  |       Amount X      Amount X-Y
        |  | Personal  |  |    ===============≠≠≠≠≠≠≠≠≠≠≠≠≠>     Strategy 1
        |  +---Pool----+--+                  ||
        | /            | /                   ||
        |/             |/                    || Amount Y
        *--------------*                     |=============>     Strategy 2
        
        @param _req ReallocateCollateralRequest struct made up of:
        * address sender - msg.sender of original tx to TFM
        * address alpha - alpha of fromStrategy (used in req collat calculations)
        * address omega - omega of fromStrategy
        * uint256 alphaCollateralRequirement - from web2 collateral params
        * uint256 omegaCollateralRequirement - from web2 collateral params
        * uint256 fromStrategyID - id of strategy to reallocate collateral from
        (cannot be 0, use allocateCollateral to allocate from unallocated)
        * uint256 toStrategyID - id of strategy to reallocate collateral to
        (0 for deallocating to unallocated)
        * uint256 amount - amount to reallocate between strategies
        * address basis - basis of both strategies
        (see Types.sol for full definition).
    */
    function reallocateCollateral(ReallocateCollateralRequest memory _req)
        external
        isTFM
    {
        // Calculating collateral requirement for the sender
        uint256 requiredCollateral;

        // Add strategy collateral requirement
        if (_req.sender == _req.alpha && _req.sender == _req.omega)
            requiredCollateral += Utils.max(
                _req.alphaCollateralRequirement,
                _req.omegaCollateralRequirement
            );
        else if (_req.sender == _req.alpha)
            requiredCollateral += _req.alphaCollateralRequirement;
        else if (_req.sender == _req.omega)
            requiredCollateral += _req.omegaCollateralRequirement;

        // Premium requirement is only relevant when caller is not on both sides of the strategy.
        // Premium should only be added to required collateral if caller corresponds to the side
        // inidicated by action.isAlpha (i.e.: the initiator), to avoid premium being withdrawn before
        // minting/transfer has been finalised (whereas the recepients premium is handled atomically in
        // claim / transferFinallise respectively).

        require(
            allocatedCollateral[_req.sender][_req.fromStrategyID] >=
                requiredCollateral + _req.amount,
            "C2" // "reallocation drops collateral below requirement (includes premium)"
        );

        _reallocateNoCollateralCheck(
            _req.sender,
            _req.fromStrategyID,
            _req.toStrategyID,
            _req.amount,
            _req.basis
        );
    }

    /**
        @notice Function called by TFM to lock up any collateral / premium / particleMass for a strategy, 
        during a multi-step process (which requires collateral).
        @dev See TFM.sol `spearmint` or `transferBegin` for more info.
        @param _req CollateralLockInitRequest struct made up of:
        * uint256 strategyID - id of strategy
        * uint256 particleMass - strategy action particleMass field
        * address alpha - alpha of strategy
        * address omega - omega of strategy
        * int256 premium - strategy mint premium
        * uint256 alphaCollateralRequirement - from web2 collateral params
        * uint256 omegaCollateralRequirement - from web2 collateral params
        * address basis - basis of strategy
        * address initiator - initiator of minting / transfer strategy
        * address targetAlpha - strategy action targetAlpha field
        * uint256 alphaCollateralRequirement - from web2 collateral params
        * uint256 omegaCollateralRequirement - from web2 collateral params
        * address basis - basis of strategy being claimed/transferd
        
        (see Types.sol for full definition).

    */
    function collateralLockExecute(CollateralLockRequest memory _req)
        external
        isTFM
    {
        //  If premium < 0: msg.sender is paying other side.
        //  If premium > 0: other side is paying msg.sender.
        uint256 requiredCollateral = _req.particleMass +
            (_req.premium < 0 ? uint256(-_req.premium) : 0);

        if ((_req.sender1 == _req.alpha) && (_req.sender1 == _req.omega)) {
            // If msg.sender is both alpha and omega, impose the maxium collateral requirement.
            requiredCollateral += Utils.max(
                _req.alphaCollateralRequirement,
                _req.omegaCollateralRequirement
            );
            if(!_req.isTransfer) {
                requiredCollateral += _req.particleMass;
            }
        } else {
            //todo: sender can be any user, why we use _omegaCollateralRequirement?
            requiredCollateral += (_req.sender1 == _req.alpha)
                ? _req.alphaCollateralRequirement
                : _req.omegaCollateralRequirement;
        }

        // Allocate required collateral to newly minted strategy for sender1.
        _autoCollateraliseStrategy(
            _req.sender1,
            _req.strategyID,
            requiredCollateral,
            _req.basis
        );

        uint256 claimerRequiredPremium = (
            _req.premium > 0 ? uint256(_req.premium) : 0
        );

        requiredCollateral =
            claimerRequiredPremium +
            _req.particleMass +
            (
                _req.isAlpha
                    ? _req.alphaCollateralRequirement
                    : _req.omegaCollateralRequirement
            );

        // Collateralise strategy, covering any collateral and premium required.
        //Won't do anything if sender1 == sender2
        _autoCollateraliseStrategy(
            _req.sender2,
            _req.strategyID,
            requiredCollateral,
            _req.basis
        );

        // Transfer premium as required.
        if (_req.premium < 0)
            relocateCollateral(
                _req.sender1,
                _req.sender2,
                _req.strategyID,
                _req.premium.abs(),
                _req.basis
            );
        else if (_req.premium > 0)
            relocateCollateral(
                _req.sender2,
                _req.sender1,
                _req.strategyID,
                _req.premium.abs(),
                _req.basis
            );

        // Transfer particle mass.
        //TODO: RENAME function, such terms create negative
        confiscateCollateral(
            _req.sender2,
            _req.strategyID,
            _req.particleMass,
            _req.basis,
            false
        );

        confiscateCollateral(
            _req.sender1,
            _req.strategyID,
            _req.particleMass,
            _req.basis,
            false
        );
    }

    /**
        @notice Function to allocate sufficient collateral to a given strategy to cover the
        required collateral.
        @dev This function takes into accunt any collateral already allocated to a given strategy
        and only allocates any remaning difference from the unallocated pool.
        @param _user address of user to allocate collateral for
        @param _strategyID the ID of the strategy to allocate collateral to
        @param _requiredCollateral the amount of collateral required (including any fees+premium)
        @param _basis the address of the ERC20 token to be used as collateral
    */
    function _autoCollateraliseStrategy(
        address _user,
        uint256 _strategyID,
        uint256 _requiredCollateral,
        address _basis
    ) internal {
        require(
            unallocatedCollateral[_user][_basis] +
                allocatedCollateral[_user][_strategyID] >=
                _requiredCollateral,
            "C15" // "_user has not deposited enough to cover premium"
        );
        // Reallocate collateral
        if (allocatedCollateral[_user][_strategyID] < _requiredCollateral) {
            _reallocateNoCollateralCheck(
                _user,
                0,
                _strategyID,
                _requiredCollateral - allocatedCollateral[_user][_strategyID],
                _basis
            );
        }
    }

    /**
        @notice Function to facilitate the finalization of a combination of two stratgies, by allocating
        the collateral of both parties from target strategy to the combined strategy.
        @param _req is the request to combineFinalise. It is a struct that contains the following in this order:
        -address sender
        -uint256 thisStrategyID
        -uint256 targetStrategyID
        -address initiator
        -uint256 particleMass
        -address basis
    */
    function combineExecute(CombineRequest memory _req) external isTFM {
        lockParticleMass(
            _req.sender,
            _req.thisStrategyID,
            _req.basis,
            _req.particleMass
        );

        // Move all allocated collateral of both parties to thisStrategy as targetStrategy will be removed.
        reallocateAllNoCollateralCheck(
            _req.sender,
            _req.targetStrategyID,
            _req.thisStrategyID,
            _req.basis
        );
        reallocateAllNoCollateralCheck(
            _req.initiator,
            _req.targetStrategyID,
            _req.thisStrategyID,
            _req.basis
        );

        // Transfer particle mass.
        confiscateCollateral(
            _req.initiator,
            _req.thisStrategyID,
            _req.particleMass,
            _req.basis,
            false
        );
        confiscateCollateral(
            _req.sender,
            _req.thisStrategyID,
            _req.particleMass,
            _req.basis,
            false
        );

        if (_req.strategiesCancelOut) {
            reallocateAllNoCollateralCheck(
                _req.sender,
                _req.thisStrategyID,
                0, //deallocate
                _req.basis
            );
            reallocateAllNoCollateralCheck(
                _req.initiator,
                _req.thisStrategyID,
                0, //deallocate
                _req.basis
            );
        }
    }

    /**
        @notice Function used to move some amout of allocated collateral from one user's personal pool to another's.
        @dev Diagram illustrating a relocation:

           +--------------+
          /|             /|
         / |            / |                                   
        *--+-----------*  |                                   
        |  |  User 1   |  |               Amount X
        |  | Personal  |  |    ≠≠≠≠≠≠≠≠≠≠≠≠≠≠==============>     Strategy
        |  +---Pool----+--+                  || Amount X+Y
        | /            | /                   ||
        |/             |/                    ||
        *--------------*                     ||
                                             ||
           +--------------+                  || Amount Y
          /|             /|                  ||
         / |            / |                  ||
        *--+-----------*  |                  ||
        |  |  User 2   |  |                  ||
        |  | Personal  |  |   ================|
        |  +---Pool----+--+
        | /            | /
        |/             |/
        *--------------*

        @param _fromUser user whose allocated funds are being decreased
        @param _toUser user whose allocated funds are being increase
        @param _strategyID strategy to which collateral is allocated
        @param _amount amount being relocated
        @param _basis basis of collateral being relocated
    */
    function relocateCollateral(
        address _fromUser,
        address _toUser,
        uint256 _strategyID,
        uint256 _amount,
        address _basis
    ) public isTFM {
        require(allocatedCollateral[_fromUser][_strategyID] >= _amount, "C16");

        address fromPool = _getOrCreatePersonalPool(_fromUser);
        address toPool = _getOrCreatePersonalPool(_toUser);

        PersonalPool(fromPool).approve(_basis, _amount);

        allocatedCollateral[_fromUser][_strategyID] -= _amount;
        allocatedCollateral[_toUser][_strategyID] += _amount;
        IERC20(_basis).safeTransferFrom(fromPool, toPool, _amount);
    }

    function reallocateNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _amount,
        address _basis
    ) external isTFM {
        _reallocateNoCollateralCheck(
            _user,
            _fromStrategyID,
            _toStrategyID,
            _amount,
            _basis
        );
    }

    /**
        @notice Function to reallocate a given amount of collateral without running checks on whether
        collateral requirements are met after reallocation.
        @param _user user to reallocate collateral of
        @param _fromStrategyID id of strategy to reallocate from
        @param _toStrategyID id of strategy to reallocate to
        @param _amount amount of allocated collateral to reallocate
        @param _basis basis of strategies
    */
    function _reallocateNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _amount,
        address _basis
    ) internal {
        if (_fromStrategyID == 0) {
            // from unallocated to allocated
            unallocatedCollateral[_user][_basis] -= _amount;
            allocatedCollateral[_user][_toStrategyID] += _amount;
        } else if (_toStrategyID == 0) {
            allocatedCollateral[_user][_fromStrategyID] -= _amount;
            unallocatedCollateral[_user][_basis] += _amount;
        } else {
            allocatedCollateral[_user][_fromStrategyID] -= _amount;
            allocatedCollateral[_user][_toStrategyID] += _amount;
        }
    }

    /**
        @notice Function to reallocate a portion (numerator/denominator) of collateral without running checks
        on whether collateral requirements are met after reallocation.
        @param _user user to reallocate collateral of
        @param _fromStrategyID id of strategy to reallocate from
        @param _toStrategyID id of strategy to reallocate to
        @param _nominator numerator of fraction of total allocated amount to reallocate
        @param _denominator denominator of fraction of total allocated amount to reallocate
        @param _basis basis of strategies
    */
    function reallocatePortionNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _nominator,
        uint256 _denominator,
        address _basis
    ) external isTFM {
        _reallocateNoCollateralCheck(
            _user,
            _fromStrategyID,
            _toStrategyID,
            (allocatedCollateral[_user][_fromStrategyID] * _nominator) /
                _denominator,
            _basis
        );
    }

    /**
        @notice Function to reallocate all collateral allocated to a strategy collateral without
        running checks on whether collateral requirements are met after reallocation.
        @param _user user to reallocate collateral of
        @param _fromStrategyID id of strategy to reallocate from
        @param _toStrategyID id of strategy to reallocate to
        @param _basis basis of strategies
    */
    function reallocateAllNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        address _basis
    ) public isTFM {
        _reallocateNoCollateralCheck(
            _user,
            _fromStrategyID,
            _toStrategyID,
            allocatedCollateral[_user][_fromStrategyID],
            _basis
        );
    }

    /**
        @notice Function called by TFM to mint a strategy for two parties by a third-party
        taking neither side of the strategy.
        @dev See TFM.sol `peppermint` function for more info.
        @param _req PeppermintRequest struct made up of:
        * address sender - msg.sender of original tx to TFM
        * uint256 strategyID - id of strategy newly minted strategy
        * address alpha - alpha of new strategy
        * address omega - omega of new strategy
        * uint256 alphaCollateralRequirement - from web2 collateral params
        * uint256 omegaCollateralRequirement - from web2 collateral params
        * address basis - basis of new strategy
        * int256 premium - strategy mint premium
        * uint256 particleMass - strategy action particleMass field
        (see Types.sol for full definition).
    */
    function peppermintExecute(PeppermintRequest memory _req) external isTFM {
        // Compute collateral required + premium per side.
        //  If premium < 0: _omega is to pay premium to _alpha.
        //  If premium > 0: _alpha is to pay premium to _omega.
        uint256 unsignedPremium = _req.premium < 0
            ? uint256(-_req.premium)
            : uint256(_req.premium);
        uint256 alphaCollateralRequirement = _req.alphaCollateralRequired +
            (_req.premium < 0 ? unsignedPremium : 0) +
            _req.particleMass;
        uint256 omegaCollateralRequirement = _req.omegaCollateralRequired +
            (_req.premium > 0 ? unsignedPremium : 0) +
            _req.particleMass;

        // Attempt to unlock the required collateral by both parties.
        _unlockCollateral(
            _req.sender,
            _req.alpha,
            _req.sender,
            _req.basis,
            alphaCollateralRequirement
        );
        _unlockCollateral(
            _req.sender,
            _req.omega,
            _req.sender,
            _req.basis,
            omegaCollateralRequirement
        );

        // Collateralise newly minted strategy for both parties, covering any collateral and premium required.
        _autoCollateraliseStrategy(
            _req.alpha,
            _req.strategyID,
            alphaCollateralRequirement,
            _req.basis
        );
        _autoCollateraliseStrategy(
            _req.omega,
            _req.strategyID,
            omegaCollateralRequirement,
            _req.basis
        );

        // Transfer premium according to the inputs.
        if (_req.premium < 0)
            relocateCollateral(
                _req.alpha,
                _req.omega,
                _req.strategyID,
                unsignedPremium,
                _req.basis
            );
        else
            relocateCollateral(
                _req.omega,
                _req.alpha,
                _req.strategyID,
                unsignedPremium,
                _req.basis
            );
        confiscateCollateral(
            _req.alpha,
            _req.strategyID,
            _req.particleMass,
            _req.basis,
            false
        );
        confiscateCollateral(
            _req.omega,
            _req.strategyID,
            _req.particleMass,
            _req.basis,
            false
        );
    }

    /**
        @notice Trusted liquidate function, where all data is assumed to be correct as
        it can be only sent by the AdminAddress (to TFM) and then sent to CM by TFM.
        @dev See TFM.sol `liquidate` function for more info.
        @param _req LiquidateRequest struct made up of:
        * strategyID id of strategy being liquidated
        * alpha alpha of strategy being liquidated
        * omega omega of strategy being liquidated
        * transferredCollateralAlpha amount transferred from omega to alpha (0 if _trasnferredCollateralOmega > 0)
        * transferredCollateralOmega amount transferred from alpha to omega (0 if _trasnferredCollateralAlpha > 0)
        * confiscatedCollateralAlpha amount confiscated by protocol from alpha
        * confiscatedCollateralOmega amount confiscated by protocol to omega
        * basis basis of strategy being liquidated
        (see Types.sol for full definition).
    */
    function liquidateExecute(LiquidateRequest memory _req) external isTFM {
        // Transfer collateral between parties.
        if (_req.transferredCollateralAlpha > 0)
            relocateCollateral(
                _req.alpha,
                _req.omega,
                _req.strategyID,
                _req.transferredCollateralAlpha,
                _req.basis
            );
        else if (_req.transferredCollateralOmega > 0)
            relocateCollateral(
                _req.omega,
                _req.alpha,
                _req.strategyID,
                _req.transferredCollateralOmega,
                _req.basis
            );

        // Confiscate collateral from the parties.
        if (_req.confiscateAlpha)  {
            confiscateCollateral(
                _req.alpha,
                _req.strategyID,
                _req.confiscatedCollateralAlpha,
                _req.basis,
                true
            );
        }

        if (_req.confiscateOmega) {
            confiscateCollateral(
                _req.omega,
                _req.strategyID,
                _req.confiscatedCollateralOmega,
                _req.basis,
                true
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";

interface ITFM {
    /************************************************
     *  Setters / Getters / Modifiers
     ***********************************************/
    function getStrategy(uint256 _strategyID)
        external
        view
        returns (Strategy memory);

    function setPhoton(address _basis, uint256 _mass) external;

    function setParticle(ActionType _action, uint256 _mass) external;

    /************************************************
     *  Collateral Management
     ***********************************************/

    function checkCollateralRequirements(
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature
    ) external view;

    function reallocateCollateral(
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _amount,
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature
    ) external;

    /************************************************
     *  Strategy Minting
     ***********************************************/
    function spearmint(
        CollateralParamsFull calldata _cParams,
        SpearmintParams calldata _aParams
    ) external;

    function peppermint(
        CollateralParamsFull calldata _params,
        bool _transferable,
        address _alpha,
        address _omega,
        bytes calldata _signature,
        int256 _premium
    ) external;

    /************************************************
     *  Actions
     ***********************************************/
    // function deleteAction(uint256 _strategyID) external;

    function annihilate(uint256 _strategyID) external;

    function transfer(
        CollateralParamsFull calldata _cParams,
        TransferParams calldata _params
    ) external;

    function combine(CombineParams calldata _params) external;

    function novate(NovateParams calldata _params) external;

    /************************************************
     *  Option Functionality
     ***********************************************/
    function exercise(
        CollateralParamsID calldata _paramsID,
        bytes calldata _signature
    ) external;

    function liquidate(
        CollateralParamsFull calldata _cParams,
        LiquidateParams calldata _lParams
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPersonalPool} from "../interfaces/IPersonalPool.sol";

/**
    @title Personal pools store collateral allocations per user.
    @notice Personal pools are created per user interacting with the TFM, to ensure separation between 
    user funds to minimise contamination risks. Collateral allocations are stored for unallocated and allocated
    collateral per basis. Users are exepected to interact with their personal pools through the TFM / Collateral Manager.
    @dev Additional documentation can be found on notion @ https://www.notion.so/trufin/V2-Documentation-6a7a43f8b577411d84277fc543f99063?d=63b28d74feba48c6be7312709a31dbe9#5bff636f9d784712af5de7df0a19ea72
*/
// TODO: this contract could be made upgradeable
contract PersonalPool is IPersonalPool {
    using SafeERC20 for IERC20;

    /**
        @notice Address of the Collateral Manager contract.
    */
    address CollateralManagerAddress;

    constructor() {
        CollateralManagerAddress = msg.sender;
    }

    /**
        @notice Modifier to check that msg.sender is the Collateral Manager.
    */
    modifier isCollateralManager() {
        require(msg.sender == CollateralManagerAddress, "A3");
        _;
    }

    /**
        @notice Function to approve the transfer of funds for msg.sender (the Collateral Manager).
        @param _basisAddress address of ERC20 token to be approved
        @param _amount of ERC20 token to approve
    */
    function approve(address _basisAddress, uint256 _amount)
        external
        isCollateralManager
    {
        IERC20(_basisAddress).safeApprove(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import {CollateralLock} from "../misc/Types.sol";

abstract contract CollateralManagerStorage {
    /**
        @notice Mapping from user to Personal Pool, where collateral is stored.
    */
    mapping(address => address) public personalPools;
    /**
        @notice User to strategyID to allocated collateral mapping. Storing the
        amount of allocated collateral a user has per strategy.
        @dev allocatedCollateral[user][strategyID]
    */
    mapping(address => mapping(uint256 => uint256)) public allocatedCollateral;
    /**
        @notice User to basis to unallocated collateral mapping. Storing the amount
        of unallocated collateral a user has per basis.
        @dev unallocatedCollateral[user][basis]
    */
    mapping(address => mapping(address => uint256))
        public unallocatedCollateral;

    /**
        @notice User to trusted locker to basis to locked collateral mapping. Storing
        the amount of collateral a user has locked for a sepcific "trusted locker" 
        per basis.
        @dev lockedCollateral[user][pepperminter][basis] = (amount, lockExpiry)
    */
    mapping(address => mapping(address => mapping(address => CollateralLock)))
        public lockedCollateral;
    /**
        @notice User to trusted locker to true/false. Mapping indicating what addresses 
        have been set as trusted lockers for a given user.
    */
    mapping(address => mapping(address => bool)) public trustedLockers;

    /**
        @dev The treasury address, to which liquidation fees are sent.
    */
    address TFMAddress;
    /**
        @dev The address of the TFM treasury, where particle fees are sent.
    */
    address TreasuryAddress;
    /**
        @dev The address of the TFM treasury, where confiscated collateral from liquidations is sent.
    */
    address InsuranceFundAddress;
    /**
        @dev the Web2 collateral message hash signer.
    */
    address public Web2Address;
    /** 
        @dev the address of the Relay responsible for updating the collateral noce.
    */
    address RelayAddress;

    /**
        @notice The nonce representing the most up-to-date version of the web2 database used to for collateral info.
    */
    uint256 public collateralNonce;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import "../misc/Types.sol";

interface ICollateralManager {
    /************************************************
     *  Modifiers & Setters
     ***********************************************/
    function setTFMAddress(address _TFMAddress) external;

    function setWeb2Address(address _Web2Address) external;

    function setRelayAddress(address _RelayAddress) external;

    /************************************************
     *  TFM Helpers
     ***********************************************/
    function confiscateCollateral(
        address _user,
        uint256 _strategyID,
        uint256 _amount,
        address _basis,
        bool _liquidation
    ) external;

    /************************************************
     *  Basic Personal Pool Functions
     ***********************************************/
    function post(address _basis, uint256 _amount) external;

    function withdraw(address _basis, uint256 _amount) external;

    /************************************************
     *  Cryptographic Collateral Verification
     ***********************************************/
    function updateCollateralNonce(
        bytes calldata _web2Sig,
        uint256 _collateralNonce
    ) external;

    /************************************************
     *  Collateral Locking
     ***********************************************/
    function changeTrustedLocker(address _locker, bool _trusted) external;

    function increaseLockedCollateral(
        address _user,
        address _basis,
        uint256 _amount,
        uint256 _lockExpiry
    ) external;

    function unlockCollateral(
        address _user,
        address _locker,
        address _basis,
        uint256 _amount
    ) external;

    /************************************************
     *  Collateral Allocation & Reallocation
     ***********************************************/
    function allocateCollateral(uint256 _toStrategyID, uint256 _amount)
        external;

    function reallocateCollateral(ReallocateCollateralRequest memory _req)
        external;

    function collateralLockExecute(CollateralLockRequest memory _req) external;

    function peppermintExecute(PeppermintRequest memory _req) external;

    function liquidateExecute(LiquidateRequest memory _req) external;

    function combineExecute(CombineRequest memory _req) external;

    function reallocateAllNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        address _basis
    ) external;

    function reallocatePortionNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _nominator,
        uint256 _denominator,
        address _basis
    ) external;

    function reallocateNoCollateralCheck(
        address _user,
        uint256 _fromStrategyID,
        uint256 _toStrategyID,
        uint256 _amount,
        address _basis
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

interface IPersonalPool {
    function approve(address _basisAddress, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}