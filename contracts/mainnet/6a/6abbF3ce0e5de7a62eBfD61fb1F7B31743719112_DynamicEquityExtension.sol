// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./storage/DynamicEquityExtensionStorage.sol";

import "./interfaces/IDynamicEquityExtension.sol";
import "../core/interfaces/IDaoRegistry.sol";

import "./libraries/DynamicEquityExtensionLibrary.sol";
import "../libraries/DaoLibrary.sol";

/// @title DynamicEquity Extension
/// @notice This contract is used to manage dynamic equity
contract DynamicEquityExtension is 
    DynamicEquityExtensionStorage,
    IDynamicEquityExtension
{
    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /// @inheritdoc IExtension
    function initialize(
        IDaoRegistry daoRegistry
    ) 
        external 
        override 
    {
        Dao storage dao = _dao();
        Initialized storage initialized = _initialized();

        if(initialized.data)
            revert DynamicEquity_AlreadyInitialized();

        dao.data = daoRegistry;

        initialized.data = true;
    }


    /**
     * MODIFIER
     */

    /// @notice 
    modifier hasExtensionAccess(
        IDaoRegistry daoRegistry, 
        DynamicEquityExtensionLibrary.AclFlag flag
    ) 
    {
        IDaoRegistry dao = _dao().data;

        if(
            dao != daoRegistry ||
            (
                address(this) != msg.sender &&
                address(dao) != msg.sender &&
                _initialized().data &&
                !DaoLibrary.isInCreationModeAndHasAccess(dao) &&
                !dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert DynamicEquity_AccessDenied();

        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquity(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityConfig memory newDynamicEquityConfig,
        DaoRegistryLibrary.EpochConfig memory newEpochConfig
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityConfig storage dynamicEquityConfig = _dynamicEquityConfig();
        EpochConfig storage epochConfig = _epochConfig();

        dynamicEquityConfig.data = newDynamicEquityConfig;
        epochConfig.data = newEpochConfig;
        epochConfig.data.epochLast = epochConfig.data.epochStart;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityEpoch(
        IDaoRegistry daoRegistry,
        uint256 newEpochLast
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DaoRegistryLibrary.EpochConfig storage epochConfig = _epochConfig().data;

        if(
            epochConfig.epochLast >= block.timestamp
            || epochConfig.epochLast >= newEpochLast
        )
            revert DynamicEquity_InvalidEpoch();

        epochConfig.epochLast = newEpochLast;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMember(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory newDynamicEquityMemberConfig
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs().data;
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        if(!DaoLibrary.isNotReservedAddress(newDynamicEquityMemberConfig.memberAddress))
            revert Extension_ReservedAddress();

        uint256 length = dynamicEquityMemberConfigs.length;

        newDynamicEquityMemberConfig.expense = 0;        
        
        if(dynamicEquityMemberIndex.data[newDynamicEquityMemberConfig.memberAddress] == 0)
        {
            dynamicEquityMemberIndex.data[newDynamicEquityMemberConfig.memberAddress] = length + 1;
            dynamicEquityMemberConfigs.push(newDynamicEquityMemberConfig);
        }
        else
        {
            dynamicEquityMemberConfigs[dynamicEquityMemberIndex.data[newDynamicEquityMemberConfig.memberAddress] - 1] = newDynamicEquityMemberConfig;
        } 
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberBatch(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory newDynamicEquityMemberConfigs
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        uint256 length = dynamicEquityMemberConfigs.data.length;

        for(uint256 i = 0; i < newDynamicEquityMemberConfigs.length; i++)
        {
            if(DaoLibrary.isNotReservedAddress(newDynamicEquityMemberConfigs[i].memberAddress))
            {
                newDynamicEquityMemberConfigs[i].expense = 0;

                if(dynamicEquityMemberIndex.data[newDynamicEquityMemberConfigs[i].memberAddress] == 0)
                {
                    dynamicEquityMemberIndex.data[newDynamicEquityMemberConfigs[i].memberAddress] = length + 1;
                    dynamicEquityMemberConfigs.data.push(newDynamicEquityMemberConfigs[i]);
                }
                else
                {
                    dynamicEquityMemberConfigs.data[dynamicEquityMemberIndex.data[newDynamicEquityMemberConfigs[i].memberAddress] - 1] = newDynamicEquityMemberConfigs[i];
                } 
            }
        }
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberSuspend(
        IDaoRegistry daoRegistry,
        address member,
        uint256 suspendedUntil
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        if(dynamicEquityMemberIndex.data[member] == 0)
            revert DynamicEquity_UndefinedMember();

        dynamicEquityMemberConfigs.data[dynamicEquityMemberIndex.data[member] - 1].suspendedUntil = suspendedUntil;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberEpoch(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata newDynamicEquityMemberEpochConfig
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberEpochConfigs storage dynamicEquityMemberEpochConfigs = _dynamicEquityMemberEpochConfigs();
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();
        EpochConfig storage epochConfig = _epochConfig();

        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory dynamicEquityMemberConfig = dynamicEquityMemberConfigs.data[dynamicEquityMemberIndex.data[newDynamicEquityMemberEpochConfig.memberAddress] - 1];
   
        if(dynamicEquityMemberIndex.data[newDynamicEquityMemberEpochConfig.memberAddress] == 0)
            revert DynamicEquity_UndefinedMember();
        
        if(!DaoLibrary.isNotReservedAddress(newDynamicEquityMemberEpochConfig.memberAddress))
            revert DynamicEquity_ReservedAddress();

        if(newDynamicEquityMemberEpochConfig.availability > dynamicEquityMemberConfig.availabilityThreshold)
            revert DynamicEquity_AvailabilityOutOfBound();

        if(newDynamicEquityMemberEpochConfig.expense > dynamicEquityMemberConfig.expenseThreshold)
            revert DynamicEquity_ExpenseOutOfBound();

        uint256 precisionFactor = 10 ** DaoLibrary.FOUNDANCE_PRECISION;
        
        uint256 expenseCommittedThreshold = dynamicEquityMemberConfig.expenseCommitted /  precisionFactor * dynamicEquityMemberConfig.expenseCommittedThreshold / 100;
       
        if(
            newDynamicEquityMemberEpochConfig.expenseCommitted / precisionFactor > dynamicEquityMemberConfig.expenseCommitted / precisionFactor + expenseCommittedThreshold 
            || newDynamicEquityMemberEpochConfig.expenseCommitted / precisionFactor < dynamicEquityMemberConfig.expenseCommitted / precisionFactor - expenseCommittedThreshold
        )
            revert DynamicEquity_ExpenseCommittedOutOfBound();
            
        uint256 withdrawalThreshold = dynamicEquityMemberConfig.withdrawal / precisionFactor * dynamicEquityMemberConfig.withdrawalThreshold / 100;
       
        if(
            newDynamicEquityMemberEpochConfig.withdrawal / precisionFactor > dynamicEquityMemberConfig.withdrawal / precisionFactor + withdrawalThreshold 
            || newDynamicEquityMemberEpochConfig.withdrawal / precisionFactor < dynamicEquityMemberConfig.withdrawal / precisionFactor - withdrawalThreshold
        )
            revert DynamicEquity_WithdrawalOutOfBound();

        dynamicEquityMemberEpochConfigs.data[epochConfig.data.epochLast + epochConfig.data.epochDuration][newDynamicEquityMemberEpochConfig.memberAddress] = newDynamicEquityMemberEpochConfig;
    }

    /// @inheritdoc IDynamicEquityExtension
    function removeDynamicEquityMemberEpoch(
        IDaoRegistry daoRegistry,
        address member
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.REMOVE_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberEpochConfigs storage dynamicEquityMemberEpochConfigs = _dynamicEquityMemberEpochConfigs();
        EpochConfig storage epochConfig = _epochConfig();

        if(_dynamicEquityMemberIndex().data[member]==0)
            revert DynamicEquity_UndefinedMember();

        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig storage dynamicEquityMemberEpochConfig = dynamicEquityMemberEpochConfigs.data[epochConfig.data.epochLast + epochConfig.data.epochDuration][member];
        dynamicEquityMemberEpochConfig.memberAddress = address(0);
    }

    /// @inheritdoc IDynamicEquityExtension
    function removeDynamicEquityMember(
        IDaoRegistry daoRegistry,
        address member
    ) 
        external
        override
        hasExtensionAccess(daoRegistry, DynamicEquityExtensionLibrary.AclFlag.REMOVE_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        dynamicEquityMemberIndex.data[member] = 0;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function getDao() 
        external 
        view
        returns(IDaoRegistry) 
    {
        // IDaoRegistry data;
        return _dao().data;
    }

    function getInitialized() 
        external 
        view
        returns(bool) 
    {
        // bool data;
        return _initialized().data;
    }

    function getEpochConfig() 
        external 
        view
        override
        returns(DaoRegistryLibrary.EpochConfig memory) 
    {
        // DaoRegistryLibrary.EpochConfig data;
        return _epochConfig().data;
    }

    function getDynamicEquityConfig() 
        external 
        view
        override
        returns(DynamicEquityExtensionLibrary.DynamicEquityConfig memory) 
    {
        // DynamicEquityExtensionLibrary.DynamicEquityConfig data;
        return _dynamicEquityConfig().data;
    }

    function getDynamicEquityMemberEpochConfigs(
        uint256 epoch,
        address memberAddress
    ) 
        external 
        view
        returns(DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory) 
    {
        // mapping(uint256 => mapping(address => DynamicEquityExtensionLibrary.DynamicEquityMemberConfig)) data;
        return _dynamicEquityMemberEpochConfigs().data[epoch][memberAddress];
    }

    function getDynamicEquityMemberConfigs()
        external 
        view
        override
        returns(DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory)
    {
        // DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] data;
        return _dynamicEquityMemberConfigs().data;
    }

    function getDynamicEquityMemberIndex(
        address memberAddress
    )
        external 
        view
        returns(uint256)
    {
        // mapping(address => uint256) data;
        return _dynamicEquityMemberIndex().data[memberAddress];
    }

    function getDynamicEquityMemberEpochAmount(
        address memberAddress
    ) 
        external 
        view
        override
        returns (uint256) 
    {
        DynamicEquityMemberEpochConfigs storage dynamicEquityMemberEpochConfigs = _dynamicEquityMemberEpochConfigs();
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();
        EpochConfig storage epochConfig = _epochConfig();

        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory dynamicEquityMemberEpochConfig = dynamicEquityMemberEpochConfigs.data[epochConfig.data.epochLast][memberAddress];

        if(dynamicEquityMemberEpochConfig.memberAddress != address(0))
        {
            return _getDynamicEquityMemberEpochAmountInternal(dynamicEquityMemberEpochConfig);
        }
        else
        {
            return _getDynamicEquityMemberEpochAmountInternal(dynamicEquityMemberConfigs.data[dynamicEquityMemberIndex.data[memberAddress] - 1]);
        }
    }

    function getDynamicEquityMemberEpoch(
        address member
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory) 
    {
        EpochConfig storage epochConfig = _epochConfig();
        return _dynamicEquityMemberEpochConfigs().data[epochConfig.data.epochLast][member];
    }

    function getDynamicEquityMemberEpoch(
        address member,
        uint256 timestamp
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory) 
    {
        return _dynamicEquityMemberEpochConfigs().data[timestamp][member];
    }

    function getIsNotReviewPeriod(
    ) 
        external 
        view
        override
        returns (bool) 
    {
        uint256 nextEpoch = _getNextEpoch();

        return (block.timestamp < nextEpoch - _epochConfig().data.epochReview);
    }

    function getVotingPeriod(
    ) 
        external 
        view
        override
        returns (uint256) 
    {
        uint256 nextEpoch = _getNextEpoch();

        return (nextEpoch + _epochConfig().data.epochDuration - block.timestamp);
    }

    function getDynamicEquityMemberConfig(
        address memberAddress
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory) 
    {
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        if(dynamicEquityMemberIndex.data[memberAddress] > 0)
            return _dynamicEquityMemberConfigs().data[dynamicEquityMemberIndex.data[memberAddress] - 1];

        revert DynamicEquity_UndefinedMember();
    }

    function getIsDynamicEquityMember(
        address memberAddress
    ) 
        external 
        view
        override
        returns (bool) 
    {
        return _dynamicEquityMemberIndex().data[memberAddress] > 0;
    }

    function getDynamicEquityMemberSuspendedUntil(
        address memberAddress
    ) 
        external 
        view
        override
        returns (uint256 suspendedUntil) 
    {
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        if(dynamicEquityMemberIndex.data[memberAddress] > 0)
            return _dynamicEquityMemberConfigs().data[dynamicEquityMemberIndex.data[memberAddress] - 1].suspendedUntil;

        revert DynamicEquity_UndefinedMember();
    }

    function getMemberConfig(      
    ) 
        external 
        view
        override
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        uint256 memberCount = getMemberCount();

        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory temp = new DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[](memberCount);

        uint256 counter = 0;

        for(uint256 i = 0; i < dynamicEquityMemberConfigs.data.length; i++)
        {
            if(dynamicEquityMemberIndex.data[dynamicEquityMemberConfigs.data[i].memberAddress] > 0)
            {
                temp[counter] = dynamicEquityMemberConfigs.data[i];
                counter++;
            }
        }

        return temp;
    }

    function getMemberConfigUnique(      
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        uint256 memberCount  = getMemberCountUnique();

        uint256[] memory indexes = new uint256[](memberCount);

        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory temp = new DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[](memberCount);
        
        uint256 counter= 0;
        uint256 index = 0; 
        
        for(uint256 i = 0; i < dynamicEquityMemberConfigs.data.length; i++)
        {
            index = dynamicEquityMemberIndex.data[dynamicEquityMemberConfigs.data[i].memberAddress];

            if(index > 0 && !_existInList(indexes, index))
            {
                temp[counter] = dynamicEquityMemberConfigs.data[index - 1];
                indexes[counter] = index;
                counter++;
            }
        }

        return temp;
    }

    function getMemberCountUnique(      
    ) 
        public 
        view 
        returns (uint256) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        uint256 counter = 0;
        uint256 index = 0;    
        
        uint256[] memory indexes = new uint256[](dynamicEquityMemberConfigs.data.length); 
        
        for(uint256 i = 0; i < dynamicEquityMemberConfigs.data.length; i++)
        {
            index = dynamicEquityMemberIndex.data[dynamicEquityMemberConfigs.data[i].memberAddress];

            if(index > 0 && !_existInList(indexes, index))
            {
                indexes[counter] = index;
                counter++;
            }
        }

        return counter;
    }

    function getMemberCount(      
    ) 
        public 
        view 
        returns (uint256) 
    {
        DynamicEquityMemberConfigs storage dynamicEquityMemberConfigs = _dynamicEquityMemberConfigs();
        DynamicEquityMemberIndex storage dynamicEquityMemberIndex = _dynamicEquityMemberIndex();

        uint256 counter = 0;        

        for(uint256 i = 0; i < dynamicEquityMemberConfigs.data.length; i++)
        {
            if(dynamicEquityMemberIndex.data[dynamicEquityMemberConfigs.data[i].memberAddress] > 0)
            {
                counter++;
            }
        }

        return counter;
    }

    function getNextEpoch(
    ) 
        external
        view
        override
        returns (uint256) 
    {
        return _getNextEpoch();
    }

    function _getNextEpoch(
    ) 
        internal 
        view 
        returns (uint256) 
    {
        EpochConfig storage epochConfig = _epochConfig();

        uint256 nextEpoch = epochConfig.data.epochLast + epochConfig.data.epochDuration;

        while(nextEpoch < block.timestamp)
        {
            nextEpoch += epochConfig.data.epochDuration;
        }

        return nextEpoch;
    }

    function _getDynamicEquityMemberEpochAmountInternal(
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory dynamicEquityMemberEpochConfig
    ) 
        internal 
        view 
        returns (uint256) 
    {
        DynamicEquityConfig storage dynamicEquityConfig = _dynamicEquityConfig();

        uint256 timeEquity = 0;
        uint256 precisionFactor = 10 ** DaoLibrary.FOUNDANCE_PRECISION;
        uint256 salaryEpoch = (dynamicEquityMemberEpochConfig.salary * dynamicEquityMemberEpochConfig.availability) / precisionFactor;

        if(salaryEpoch > dynamicEquityMemberEpochConfig.withdrawal / precisionFactor)
        {
            timeEquity = ((salaryEpoch - dynamicEquityMemberEpochConfig.withdrawal / precisionFactor) * dynamicEquityConfig.data.timeMultiplier / precisionFactor);
        }

        uint256 riskEquity = ((dynamicEquityMemberEpochConfig.expense / precisionFactor + dynamicEquityMemberEpochConfig.expenseCommitted / precisionFactor) * dynamicEquityConfig.data.riskMultiplier / precisionFactor);
        
        return timeEquity + riskEquity;
    }

    function _existInList(
        uint256[] memory list, 
        uint256 value     
    ) 
        internal 
        pure 
        returns (bool) 
    {          
        for(uint256 i = 0; i < list.length; i++)
        {
            if(list[i] == value)
            {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/interfaces/IDaoRegistry.sol";

import "../libraries/DynamicEquityExtensionLibrary.sol";
import "../../core/libraries/DaoRegistryLibrary.sol";

/// @title DynamicEquity Extension Storage
/// @notice This contract defines the storage struct and the memory pointer for the DynamicEquityExtension contract
contract DynamicEquityExtensionStorage{
    /**
     * STORAGE STRUCTS
     */

    struct Dao{
        /// @notice
        IDaoRegistry data;
    }

    struct Initialized{
        /// @notice
        bool data;
    }

    struct EpochConfig{
        /// @notice
        DaoRegistryLibrary.EpochConfig data;
    }

    struct DynamicEquityConfig{
        /// @notice
        DynamicEquityExtensionLibrary.DynamicEquityConfig data;
    }

    struct DynamicEquityMemberEpochConfigs{
        /// @notice
        mapping(uint256 => mapping(address => DynamicEquityExtensionLibrary.DynamicEquityMemberConfig)) data;
    }

    struct DynamicEquityMemberConfigs{
        /// @notice 
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] data;
    }

    struct DynamicEquityMemberIndex{
        /// @notice 
        mapping(address => uint256) data;
    }


    /**
     * STORAGE POINTER
     */

    function _dao() 
        internal 
        pure 
        returns(Dao storage data) 
    {
        // data = keccak256("dynamicEquityExtension.dao")
        assembly {data.slot := 0x2fd2d3362181db67fecc559d404b623ab6cc1779a69b2698d343ef9839437181}
    }

    function _initialized() 
        internal 
        pure 
        returns(Initialized storage data) 
    {
        // data = keccak256("dynamicEquityExtension.initialized")
        assembly {data.slot := 0xa8eb0f5eb5e853907112ce6c193c1af0f3a99290c7d0f76fbe4a3838ae2947b5}
    }

    function _epochConfig() 
        internal 
        pure 
        returns(EpochConfig storage data) 
    {
        // data = keccak256("dynamicEquityExtension.epochConfig")
        assembly {data.slot := 0x2627e97067e7fccc10a42c2f72f55de0cf40b0b752951dd223b0dbc04b830ad0}
    }

    function _dynamicEquityConfig() 
        internal 
        pure 
        returns(DynamicEquityConfig storage data) 
    {
        // data = keccak256("dynamicEquityExtension.dynamicEquityConfig")
        assembly {data.slot := 0xe42c5bd33150466afaf3935e661e60cefdce0314a6e9f8d64b667b35d12dea52}
    }

    function _dynamicEquityMemberEpochConfigs() 
        internal 
        pure 
        returns(DynamicEquityMemberEpochConfigs storage data) 
    {
        // data = keccak256("dynamicEquityExtension.dynamicEquityMemberEpochConfigs")
        assembly {data.slot := 0x2cbbb1ef5df79c3b8094c6b7615156e23488f7895a61cd942b5ef972c75f17f2}
    }

    function _dynamicEquityMemberConfigs()
        internal
        pure
        returns(DynamicEquityMemberConfigs storage data)
    {
        // data = keccak256("dynamicEquityExtension.dynamicEquityMemberConfigs")
        assembly {data.slot := 0xcb95a460adbc6e30096ad298137f0c426294a07c4fa09c426e71b05d2805b4f9}
    }

    function _dynamicEquityMemberIndex()
        internal
        pure
        returns(DynamicEquityMemberIndex storage data)
    {
        // data = keccak256("dynamicEquityExtension.dynamicEquityMemberIndex")
        assembly {data.slot := 0xad200ef468e49d9db20a936bc71ad9f4022cd81e3bfce3fe2787c7ea2c5512e6}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./errors/IDynamicEquityExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

import "../libraries/DynamicEquityExtensionLibrary.sol";
import "../../core/libraries/DaoRegistryLibrary.sol";

/// @title DynamicEquity Extension Interface
/// @notice This interface defines the functions for the DynamicEquity Extension
interface IDynamicEquityExtension is
    IExtension,
    IDynamicEquityExtensionErrors    
{
    function setDynamicEquity(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityConfig calldata dynamicEquiytyConfig,
        DaoRegistryLibrary.EpochConfig calldata epochConfig
    ) 
        external;

    function setDynamicEquityEpoch(
        IDaoRegistry daoRegistry,
        uint256 newEpochLast
    ) 
        external;

    function setDynamicEquityMember(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory dynamicEquityMemberConfig
    ) 
        external;

    function setDynamicEquityMemberBatch(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory dynamicEquityMemberConfig
    ) 
        external;

    function setDynamicEquityMemberSuspend(
        IDaoRegistry daoRegistry,
        address _member,
        uint256 suspendedUntil
    ) 
        external;

    function setDynamicEquityMemberEpoch(
        IDaoRegistry daoRegistry,
        DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata config
    ) 
        external; 

    function removeDynamicEquityMemberEpoch(
        IDaoRegistry daoRegistry,
        address _member
    ) 
        external;

    function removeDynamicEquityMember(
        IDaoRegistry daoRegistry,
        address _member
    ) 
        external;

    function getIsNotReviewPeriod(
    ) 
        external 
        view 
        returns (bool);

    function getNextEpoch(
    ) 
        external
        view 
        returns (uint256);

    function getVotingPeriod(
    ) 
        external 
        view 
        returns (uint256);

    function getEpochConfig(
    ) 
        external
        view
        returns (DaoRegistryLibrary.EpochConfig memory);

    function getIsDynamicEquityMember(
        address memberAddress
    ) 
        external 
        view 
        returns (bool);

    function getDynamicEquityMemberSuspendedUntil(
        address memberAddress
    ) 
        external 
        view 
        returns (uint256 suspendedUntil);

    function getDynamicEquityMemberEpochAmount(
        address memberAddress
    ) 
        external 
        view 
        returns (uint);

    function getMemberConfig(      
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory);

    function getDynamicEquityConfig(
    ) 
        external 
        view
        returns (DynamicEquityExtensionLibrary.DynamicEquityConfig memory);

    function getDynamicEquityMemberConfigs(
    ) 
        external 
        view 
        returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory);
}

// SPDX-License-Identifier: MITis
pragma solidity 0.8.17;

import "./events/IDaoRegistryEvents.sol";
import "./errors/IDaoRegistryErrors.sol";
import "../../extensions/interfaces/IExtension.sol";
import "../../proxy/interfaces/ILighthouse.sol";

import "../libraries/DaoRegistryLibrary.sol";

/// @title Dao Registry interface
/// @notice This interface defines the functions that can be called on the DaoRegistry contract
interface IDaoRegistry is
    IDaoRegistryEvents,
    IDaoRegistryErrors
{
    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO"s creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    function initialize(
        address creator, 
        address payer
    ) 
        external;

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() 
        external;

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() 
        external;

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() 
        external;

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(
        bytes32 key, 
        uint256 value
    )
        external;

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(
        bytes32 key, 
        address value
    )
        external;

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) 
        external;

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    function addExtension(
        bytes32 extensionId, 
        IExtension extension
    )
        external;

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(
        bytes32 extensionId
    )
        external;

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    )   
        external;

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(
        bytes32 proposalId
    )
        external;

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) 
        external;

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(
        bytes32 proposalId
    ) 
        external;

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(
        address memberAddress
    )
        external;

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(
        address memberAddress
    )
        external;

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(
        address memberAddr, 
        address newDelegateKey
    )
        external;

    function setDelegatedSource(
        address lighthouseAddress,
        address delegatedSource
    )
        external;

    function setImplementationBatch(
        address lighthouse,
        address[] calldata newImplementationAddresses,
        bytes32[] calldata newImplementationIds
    )
        external;

    function potentialNewMember(
        address memberAddress
    )
        external;

    function getNbMembers(
    ) 
        external 
        view 
        returns (uint256);

    function getLockedAt(
    )
        external 
        view
        returns (uint256); 

    function getMemberAddress(
        uint256 index
    ) 
        external 
        view
        returns (address);

    function getPreviousDelegateKey(
        address memberAddr
    )
        external
        view
        returns (address);

    function getAddressIfDelegated(
        address checkAddr
    )
        external
        view
        returns (address);

    function getCurrentDelegateKey(
        address memberAddr
    )
        external
        view
        returns (address);

    function getState(
    ) 
        external 
        view 
        returns (DaoRegistryLibrary.DaoState);

    function isMember(
        address addr
    ) 
        external 
        view 
        returns (bool);

    function isAdapter(
        address adapterAddress
    ) 
        external
        view
        returns (bool);

    function getExtensionAddress(
        bytes32 extensionId
    )
        external
        view
        returns (address);

    function hasAdapterAccess(
        address adapterAddress, 
        DaoRegistryLibrary.AclFlag flag
    )
        external
        view
        returns (bool);

    function getAdapterAddress(
        bytes32 adapterId
    )
        external
        view
        returns (address);

    function getVotingAdapter(
        bytes32 votingAdapterId
    ) 
        external 
        view 
        returns (address);

    function getProposals(
        bytes32 proposalId
    ) 
        external 
        view 
        returns (DaoRegistryLibrary.Proposal memory);

    function getAddressConfiguration(
        bytes32 key
    )
        external
        view
        returns(address);

    function getExtensions(
        bytes32 extensionId
    ) 
        external 
        view 
        returns (address);

    function getIsProposalUsed(
        bytes32 proposalId
    )
        external
        view
        returns (bool);

    function getProposalFlag(
        bytes32 proposalId,
        DaoRegistryLibrary.ProposalFlag flag
    )
        external
        view
        returns (bool);

    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) 
        external 
        view 
        returns (bool);

    function notJailed(
        address memberAddress
    ) 
        external 
        view 
        returns (bool);

    function getMainConfiguration(
        bytes32 id
    ) 
        external 
        view 
        returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Extension Library
/// @notice This library defines the structs used by the Dynamic Equity Extension
library DynamicEquityExtensionLibrary {
    /**
     * ENUMS
     */

    enum AclFlag {
        SET_DYNAMIC_EQUITY,
        REMOVE_DYNAMIC_EQUITY,
        ACT_DYNAMIC_EQUITY
    }


    /**
     * STRUCTS
     */

    struct DynamicEquityMemberConfig {
        address memberAddress;
        uint256 suspendedUntil;
        uint256 availability;
        uint256 availabilityThreshold;
        uint256 salary;
        uint256 salaryYear;
        uint256 withdrawal;
        uint256 withdrawalThreshold;
        uint256 expense;
        uint256 expenseThreshold;
        uint256 expenseCommitted;
        uint256 expenseCommittedThreshold;
    }

    struct DynamicEquityConfig {
        uint256 riskMultiplier;
        uint256 timeMultiplier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/interfaces/IDaoRegistry.sol";
import "../extensions/interfaces/IBankExtension.sol";

import "../core/libraries/DaoRegistryLibrary.sol";

library DaoLibrary {
    /**
     * PRIVATE VARIABLES
     */

    ///@notice Foundance
    bytes32 internal constant FOUNDANCE = keccak256("foundance");

    ///@notice Dao Registry
    bytes32 internal constant DAO_EXT = keccak256("dao-ext");

    ///@notice Bank Extension
    bytes32 internal constant BANK_EXT = keccak256("bank-ext");

    ///@notice ERC20 Extension
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");

    ///@notice Member Extension
    bytes32 internal constant MEMBER_EXT = keccak256("member-ext"); 

    ///@notice Dynamic Equity Extension
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");

    ///@notice Vested Equity Extension
    bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext");

    ///@notice Community Equity Extension
    bytes32 internal constant COMMUNITY_EQUITY_EXT = keccak256("community-equity-ext"); 
    
    ///@notice ERC20 Adapter
    bytes32 internal constant ERC20_ADPT = keccak256("erc20-adpt");

    ///@notice Member Adapter
    bytes32 internal constant MANAGER_ADPT = keccak256("manager-adpt");

    ///@notice Voting Adapter
    bytes32 internal constant VOTING_ADPT = keccak256("voting-adpt");

    ///@notice Member Adapter
    bytes32 internal constant MEMBER_ADPT = keccak256("member-adpt"); 

    ///@notice Dynamic Equity Adapter
    bytes32 internal constant DYNAMIC_EQUITY_ADPT = keccak256("dynamic-equity-adpt");

    ///@notice Vested Equity Adapter
    bytes32 internal constant VESTED_EQUITY_ADPT = keccak256("vested-equity-adpt");

    ///@notice Community Equity Adapter
    bytes32 internal constant COMMUNITY_EQUITY_ADPT = keccak256("community-equity-adpt");

    ///@notice GUILD Address
    address internal constant GUILD = address(0xdead);

    ///@notice ESCROW Address
    address internal constant ESCROW = address(0x4bec);

    ///@notice TOTAL Address
    address internal constant TOTAL = address(0xbabe);

    ///@notice UNITS Address
    address internal constant UNITS = address(0xFF1CE);

    ///@notice LOOT Address
    address internal constant LOOT = address(0xB105F00D);

    ///@notice ETH_TOKEN Address
    address internal constant ETH_TOKEN = address(0x0);

    ///@notice MEMBER_COUNT Address
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    ///@notice config COMMUNITY_EQUITY_ID for the Community Equity Extension initial pool
    bytes32 internal constant COMMUNITY_EQUITY = keccak256("community-equity");

    ///@notice config floating point precision
    uint256 internal constant FOUNDANCE_PRECISION = 5;

    ///@notice config MAX_TOKENS_GUILD_BANK for the Bank Extension
    uint8   internal constant MAX_TOKENS_GUILD_BANK = 200;

    
    /**
     * INTERNAL FUNCTIONS
     */

    function sqrt(
        uint256 y
    ) 
        internal 
        pure 
        returns (uint256 z) 
    {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    function getFlag(
        uint256 flags, 
        uint256 flag
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) 
        internal 
        pure 
        returns (uint256) 
    {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(
        address addr
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(
        address addr
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        IDaoRegistry dao,
        IBankExtension bank
    ) 
        internal 
    {
        dao.potentialNewMember(memberAddress);

        require(
            memberAddress != address(0x0), 
            "invalid member address"
        );
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) 
            {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function totalTokens(
        IBankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        //GUILD is accounted for twice otherwise
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); 
    }

    function totalUnitTokens(
        IBankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        //GUILD is accounted for twice otherwise
        return  bank.balanceOf(TOTAL, UNITS) - bank.balanceOf(GUILD, UNITS); 
    }

    function totalQuadraticTokens(
        IDaoRegistry dao,
        IBankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 nbMembers = dao.getNbMembers();

        uint256 memberToken = 0;
        for (uint256 i = 0; i < nbMembers; i++) {
            address memberAddress = dao.getMemberAddress(i);
            memberToken += sqrt(bank.balanceOf(memberAddress, UNITS));
        }
        return  memberToken; 
    }

    function totalCooperativeTokens(
        IDaoRegistry dao,
        IBankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 nbMembers = dao.getNbMembers();
        uint256 memberToken = 0;
        for (uint256 i = 0; i < nbMembers; i++) {
            address memberAddress = dao.getMemberAddress(i);
            if(bank.balanceOf(memberAddress, UNITS)>0)
                memberToken++;
        }
        return memberToken;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(
        IBankExtension bank, 
        uint256 at
    )
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(
        IBankExtension bank, 
        address member
    )
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(
        IDaoRegistry dao, 
        address addr
    )
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        IBankExtension bank,
        address member,
        uint256 at
    ) 
        internal 
        view 
        returns (uint256) 
    {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(
        IDaoRegistry dao
    )
        internal
        view
        returns (bool)
    {
        return
            dao.getState() == DaoRegistryLibrary.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IDaoRegistry.sol";

import "../../libraries/DaoLibrary.sol";

/// @title Dao Registry Library
/// @notice This library contains all the structs and enums used by the DaoRegistry contract
library DaoRegistryLibrary{
    /**
     * ENUMS
     */

    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER,
        SET_PROXY_IMPLEMENTATION
    }


    /**
     * STRUCTS
     */
    
    /// @notice The structure to track all the proposals in the DAO
    struct Proposal {
        ///@notice the adapter address that called the functions to change the DAO state
        address adapterAddress; 
        ///@notice flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
        uint256 flags; 
    }

    ///@notice the structure to track all the members in the DAO
    struct Member {
        ///@notice flags to track the state of the member: exists, etc
        uint256 flags; 
    }

    ///@notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint96 fromBlock;
        uint160 amount;
    }

    struct EpochConfig {
        uint256 epochDuration;
        uint256 epochReview;
        uint256 epochStart;
        uint256 epochLast;
    }
    
    ///@notice A checkpoint for marking the delegate key for a member from a given block
    struct DelegateCheckpoint {
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Events
/// @notice This interface defines the events for DaoRegistry
interface IDaoRegistryEvents {
    /**
      * EVENTS
      */

    event SubmittedProposal(
        bytes32 proposalId, 
        uint256 flags
    );
    
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    
    event ProcessedProposal(
        bytes32 proposalId, 
        uint256 flags
    );
    
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    
    event AdapterRemoved(
        bytes32 adapterId
    );
    
    event ExtensionAdded(
        bytes32 extensionId, 
        address extensionAddress
    );
    
    event ExtensionRemoved(
        bytes32 extensionId
    );
    
    event UpdateDelegateKey(
        address memberAddress, 
        address newDelegateKey
    );
    
    event UpdateProxyConfiguration(
        address lighthouse, 
        address delegatedSource
    );

    event SetImplementationBatch(
        address lighthouse,
        address source,
        address[] implementationAddresses,
        bytes32[] implementationIds
    );

    event SetDelegatedSource(
        address lighthouse,
        address source,
        address delegatedSource
    );
    
    event ConfigurationUpdated(
        bytes32 key, 
        uint256 value
    );
    
    event AddressConfigurationUpdated(
        bytes32 key, 
        address value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Errors
/// @notice This interface defines the errors for DaoRegistry
interface IDaoRegistryErrors {
    /**
      * ERRORS
      */

    error DaoRegistry_AlreadyInitialized();

    error DaoRegistry_AccessDenied();

    error DaoRegistry_NotAllowedToFinalize();

    error DaoRegistry_EmptyExtensionId();

    error DaoRegistry_RegisteredExtensionId();

    error DaoRegistry_UnregisteredExtensionId();

    error DaoRegistry_DeletedExtension();

    error DaoRegistry_AdapterNotFound();

    error DaoRegistry_AdapterMismatch();

    error DaoRegistry_EmptyAdapterId();

    error DaoRegistry_RegisteredAdapterId();

    error DaoRegistry_UnregisteredAdapterId();

    error DaoRegistry_AlreadySetFlag();

    error DaoRegistry_InvalidProposalId();

    error DaoRegistry_NotExistingProposalId();

    error DaoRegistry_NotUniqueProposalId();

    error DaoRegistry_AlreadyProcessedProposalId();

    error DaoRegistry_InvalidMember();

    error DaoRegistry_NotExistingMember();

    error DaoRegistry_BlockNumberNotFinalized();

    error DaoRegistry_InvalidDelegateKey();

    error DaoRegistry_DelegateKeyAlreadyTaken();

    error DaoRegistry_DelegateKeyAddressAlreadyTaken();

    error DaoRegistry_MemberAddressAlreadyUsedAsDelegate();

    error DaoRegistry_InvalidLighthouseAddress();

    error DaoRegistry_InvalidImplementationArrayLength();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

/// @title Extension Interface
/// @notice This interface defines the functions for the Extension
interface IExtension is
    IExtensionErrors
{
    /**
     * EXTERNAL FUNCTIONS
     */
    
    function initialize(
        IDaoRegistry daoRegistry
    ) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./errors/ILighthouseErrors.sol";
import "./events/ILighthouseEvents.sol";

/// @title Lighthouse
/// @notice This interface defines the functions that a Lighthouse must implement
interface ILighthouse is
    ILighthouseErrors,
    ILighthouseEvents
{
    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev address must be contract
     */

    function initializeSource(
        address sourceOwner,
        address delegatedSource
    ) 
        external;

    function changeImplementationBatch(
        address source,
        address[] memory implementationAddresses,
        bytes32[] memory implementationIds
    ) 
        external;

    function changeDelegatedSource(
        address source,
        address newDelegatedSource
    ) 
        external;

    function isInitialized(
        address source
    ) 
        external
        view
        returns(bool);

    function getImplementation(
        address source,
        bytes32 id
    ) 
        external 
        view 
        returns (address);

    function getSourceOwner(
        address source
    ) 
        external 
        view 
        returns (address);

    function getDelegatedSource(
        address source
    ) 
        external 
        view 
        returns (address);

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Errors
/// @notice This interface defines the errors for the Extension
interface IExtensionErrors {
    /**
     * ERRORS
     */
    
    error Extension_ReservedAddress();
    
    error Extension_NotAMember(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Lighthouse Errors
/// @notice This interface defines the errors for Lighthouse
interface ILighthouseErrors{
    /**
     * ERRORS
     */
    
    error Lighthouse_ImplementationNotContract();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Events emitted by the Lighthouse
/// @notice Contains all events emitted by the Lighthouse
interface ILighthouseEvents{
    /**
     * EVENTS
     */

    /**
     * @dev Emitted when the source has changed.
     */
    event SourceChanged(
        address previousSource, 
        address newSource
    );

    /**
     * @dev Emitted when the source has changed.
     */
    event IdChanged(
        bytes32 previousId, 
        bytes32 newId
    );

    /**
     * @dev Emitted when the implementation returned by the lighthouse is changed.
     */
    event ImplementationChanged(
        address source,
        bytes32 id,
        address implementation
    );

    /**
     * @dev
     */
    event SourceOwnerTransferred(
        address source, 
        address previousOwner, 
        address newOwner
    );

    /**
     * @dev
     */
    event DelegatedSourceChanged(
        address source, 
        address newDelegatedSource
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./errors/IBankExtensionErrors.sol";
import "./events/IBankExtensionEvents.sol";
import "../../core/interfaces/IDaoRegistry.sol";

/// @title Bank Extension Interface
/// @notice This interface defines the functions for the Bank Extension
interface IBankExtension is
    IExtension,
    IBankExtensionErrors,
    IBankExtensionEvents 
{
    /**
     * EXTERNAL FUNCTIONS
     */

    function withdraw(
        IDaoRegistry daoRegistry,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) 
        external;

    function withdrawTo(
        IDaoRegistry daoRegistry,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) 
        external;

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(
        uint8 maxTokens
    ) 
        external;

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(
        IDaoRegistry daoRegistry, 
        address token
    )
        external;

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(
        IDaoRegistry daoRegistry, 
        address token
    )
        external;

    function updateToken(
        IDaoRegistry daoRegistry, 
        address tokenAddr
    )
        external;

    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) 
        external 
        view 
        returns (uint256);

    function addToBalance(
        IDaoRegistry daoRegistry,
        address member,
        address token,
        uint256 amount
    ) 
        external 
        payable;

    function addToBalanceBatch(
        IDaoRegistry daoRegistry,
        address[] memory member,
        address token,
        uint256[] memory amount
    ) 
        external
        payable;

    function subtractFromBalance(
        IDaoRegistry daoRegistry,
        address member,
        address token,
        uint256 amount
    ) 
        external;

    function balanceOf(
        address member, 
        address tokenAddr
    )
        external
        view
        returns (uint160);

    function internalTransfer(
        IDaoRegistry daoRegistry,
        address from,
        address to,
        address token,
        uint256 amount
    ) 
        external;

    function isInternalToken(
        address token
    ) 
        external 
        view 
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Errors
/// @notice This interface defines the errors for Bank Extension
interface IBankExtensionErrors {
    /**
     * ERRORS
     */
    
    error Bank_AccessDenied();

    error Bank_AlreadyInitialized();
    
    error Bank_NotEnoughFunds();

    error Bank_TooManyExternalTokens();

    error Bank_TooManyInternalTokens();

    error Bank_ExternalTokenAmountLimitExceeded();

    error Bank_InternalTokenAmountLimitExceeded();

    error Bank_UnregisteredToken();

    error Bank_BlockNumberNotFinalized();

    error Bank_NoTransferFromJailedMember(address member);

    error Bank_NoTransferToJailedMember(address member);

    error Bank_NotImplemented();

    error Bank_MaxExternalTokensOutOfRange();

    error Bank_TokenAlreadyInternal(address token);

    error Bank_TokenAlreadyExternal(address token);

    error Bank_TokenNotRegistered(address token);

    error Bank_NotAMember(address member);
    
    error Bank_DaoLocked();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Events
/// @notice This interface defines the events for Bank Extension
interface IBankExtensionEvents {
    /**
     * EVENTS
     */

    event NewBalance(
        address member,
        address tokenAddr,
        uint160 amount
    );

    event Withdraw(
        address account, 
        address tokenAddr, 
        uint160 amount
    );

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Extension Errors
/// @notice This interface defines the errors for Dynamic Equity Extension
interface IDynamicEquityExtensionErrors {
    /**
     * ERRORS
     */

    error DynamicEquity_AccessDenied();

    error DynamicEquity_AlreadyInitialized();

    error DynamicEquity_InvalidEpoch();

    error DynamicEquity_InvalidCommunityEquity();

    error DynamicEquity_UndefinedMember();

    error DynamicEquity_ReservedAddress();

    error DynamicEquity_AvailabilityOutOfBound();

    error DynamicEquity_ExpenseOutOfBound();

    error DynamicEquity_ExpenseCommittedOutOfBound();

    error DynamicEquity_WithdrawalOutOfBound();
}