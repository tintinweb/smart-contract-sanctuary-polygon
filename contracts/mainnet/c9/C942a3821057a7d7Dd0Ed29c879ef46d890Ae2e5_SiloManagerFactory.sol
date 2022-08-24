// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../interfaces/ISiloManager.sol";
import {KeeperRegistryInterface, State, Config} from "../../chainlink/interfaces/KeeperRegistryInterface.sol";
import "../../chainlink/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../../interfaces/ILinkToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IPegSwap.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";

contract SiloManagerFactory is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public managerImplementation;
    mapping(address => bool) public isManager;
    //address public keeperRegistry;
    address public siloFactory;
    KeeperRegistryInterface Registry;
    mapping(address => address) public userToManager;
    uint256 public minFundingAmount = 5000000000000000000; //5 Link
    uint256 public lastCheckedUpkeepId = 0;
    uint256 public maxBatchSize = 450;
    uint32 public GAS_LIMIT = 5000000;
    uint8 public SOURCE = 144;
    uint64 private constant UINT64_MAX = 2**64 - 1;
    uint256 public managerCount;
    // mapping(address => uint) public managerId;
    uint256[] public managerUpkeeps;

    bool public factoryUpkeepCreated;

    uint96 public riskBuffer = 15000; //based off a number 10000 -> ∞
    uint96 public rejoinBuffer = 30000;

    //mumbai
    //address public REGISTRAR_ADDRESS = 0xF43c9134Ae10f06efA914a8B1ca3B5d468130f47;
    //address constant public ERC677_LINK_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    //ftm test
    //address public REGISTRAR_ADDRESS = 0x7b3EC232b08BD7b4b3305BE0C044D907B2DF960B;
    //address constant public ERC677_LINK_ADDRESS = 0xfaFedb041c0DD4fA2Dc0d87a6B0979Ee6FA7af5F;

    //polygon
    address public constant ERC20_LINK_ADDRESS =
        0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39; //Mainnet ERC20 _LINK_ADDRESS
    address public constant ERC677_LINK_ADDRESS =
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant PEGSWAP_ADDRESS =
        0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;

    address public REGISTRAR_ADDRESS =
        0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d; //Mainnet
    bytes4 private constant FUNC_SELECTOR =
        bytes4(
            keccak256(
                "register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"
            )
        );

    IERC20 ERC20Link = IERC20(ERC20_LINK_ADDRESS);
    // ILinkToken ERC677Link = ILinkToken(ERC677_LINK_ADDRESS);
    LinkTokenInterface ERC677Link = LinkTokenInterface(ERC677_LINK_ADDRESS);
    IPegSwap PegSwap = IPegSwap(PEGSWAP_ADDRESS);

    //for migrations
    uint256 public migrationBorrow = 2500000000000000000; //how much Link Managers "borrow" to migrate their upkeep
    uint256 public minMigrationBalance = 5000000000000000000; //min balance needed to have upkeep automatically migrated
    EnumerableSet.UintSet private upkeepSetAlpha;
    EnumerableSet.UintSet private upkeepSetBeta;
    bool public alphaOrBeta = true; //initially used alpha registry
    EnumerableSet.UintSet private needSponsor; //used to temporarily store upkeeps that need a sponsor
    bool public migrate;
    address public alphaRegistry;
    address public betaRegistry;
    uint256 public sponsorFee = 100; //based of 10000 ie 1%

    constructor(
        address _keeperRegistry,
        address _siloFactory,
        address _managerImplementation
    ) {
        alphaRegistry = _keeperRegistry;
        Registry = KeeperRegistryInterface(_keeperRegistry);
        (, Config memory _config, ) = Registry.getState();
        REGISTRAR_ADDRESS = _config.registrar;
        siloFactory = _siloFactory;
        managerImplementation = _managerImplementation;
    }

    function udpateSiloFactory(address _siloFactory) external onlyOwner {
        siloFactory = _siloFactory;
    }

    function adjustRiskBuffer(uint96 _buffer) external onlyOwner {
        require(_buffer > 10000, "Risk Buffer not valid");
        riskBuffer = _buffer;
    }

    function adjustRejoinBuffer(uint96 _buffer) external onlyOwner {
        require(_buffer > 10000, "Rejoin Buffer not valid");
        rejoinBuffer = _buffer;
    }

    function adjustMaxBatchSize(uint256 _newBatchSize) external onlyOwner {
        maxBatchSize = _newBatchSize;
    }

    function adjustMinFundingAmount(uint256 _amount) external onlyOwner {
        minFundingAmount = _amount;
    }

    function updateCurrentKeepersRegistry(address _registry)
        external
        onlyOwner
    {
        if (alphaOrBeta) {
            alphaRegistry = _registry;
        } else {
            betaRegistry = _registry;
        }
        Registry = KeeperRegistryInterface(_registry);
        (, Config memory _config, ) = Registry.getState();
        REGISTRAR_ADDRESS = _config.registrar;
    }

    function adjustSponsorFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Sponsor Fee capped at 10%");
        sponsorFee = _newFee;
    }

    // function startMigration(
    //     address _newRegistry,
    //     uint256 _migrationBorrow,
    //     uint256 _minMigrationBalance,
    //     address _registrar
    // ) external onlyOwner {
    //     if (alphaOrBeta) {
    //         require(
    //             upkeepSetBeta.length() == 0,
    //             "Beta Upkeep set still has upkeeps in it"
    //         );
    //         alphaOrBeta = false;
    //         betaRegistry = _newRegistry;
    //     } else {
    //         require(
    //             upkeepSetAlpha.length() == 0,
    //             "Alpha Upkeep set still has upkeeps in it"
    //         );
    //         alphaOrBeta = true;
    //         alphaRegistry = _newRegistry;
    //     }
    //     migrationBorrow = _migrationBorrow;
    //     minMigrationBalance = _minMigrationBalance;
    //     migrate = true;
    //     Registry = KeeperRegistryInterface(getKeeperRegistry());
    //     REGISTRAR_ADDRESS = _registrar;
    // }

    // function stopMigration() external onlyOwner {
    //     if (alphaOrBeta) {
    //         require(
    //             upkeepSetBeta.length() == 0,
    //             "Beta Upkeep set still has upkeeps in it"
    //         );
    //     } else {
    //         require(
    //             upkeepSetAlpha.length() == 0,
    //             "Alpha Upkeep set still has upkeeps in it"
    //         );
    //     }
    //     migrate = false;
    // }

    // function migrationCancel() external {
    //     require(isManager[msg.sender], "Only managers can call this");
    //     uint256 id = ISiloManager(msg.sender).upkeepId();
    //     require(id != 0, "Manager not approved");
    //     require(
    //         ERC677Link.balanceOf(address(this)) >= migrationBorrow,
    //         "Not enough funds to migrate!"
    //     );
    //     if (alphaOrBeta) {
    //         //moving from beta to alpha
    //         upkeepSetBeta.remove(id); //remove id  from alpha set
    //     } else {
    //         //moving from alpha to beta
    //         upkeepSetAlpha.remove(id);
    //     }
    //     KeeperRegistryInterface(getOldKeeperRegistry()).cancelUpkeep(id);
    //     ERC677Link.approve(getKeeperRegistry(), migrationBorrow);
    //     KeeperRegistryInterface(getKeeperRegistry()).addFunds(
    //         id,
    //         uint96(migrationBorrow)
    //     );
    // }

    // function migrationWithdraw() external {
    //     require(isManager[msg.sender], "Only managers can call this");
    //     uint256 id = ISiloManager(msg.sender).upkeepId();
    //     require(id != 0, "Manager not approved");
    //     (
    //         ,
    //         ,
    //         ,
    //         uint96 balance,
    //         ,
    //         ,
    //         uint256 maxValidBlocknumber,

    //     ) = KeeperRegistryInterface(getOldKeeperRegistry()).getUpkeep(id);
    //     uint256 bal = uint256(balance);
    //     require(
    //         block.number > maxValidBlocknumber,
    //         "Gravity Finance: Max Valid Block not reached yet"
    //     );
    //     if (alphaOrBeta) {
    //         upkeepSetAlpha.add(id);
    //     } else {
    //         upkeepSetBeta.add(id);
    //     }

    //     KeeperRegistryInterface(getOldKeeperRegistry()).withdrawFunds(
    //         id,
    //         address(this)
    //     );

    //     if (bal > migrationBorrow) {
    //         //users could technically have their upkeep burn a ton of Link while the migration is happening, but that only benefits keepers
    //         uint256 fundsToReturn = bal - migrationBorrow;
    //         ERC677Link.approve(getKeeperRegistry(), fundsToReturn);
    //         KeeperRegistryInterface(getKeeperRegistry()).addFunds(
    //             id,
    //             uint96(fundsToReturn)
    //         );
    //     }
    // }

    function createSiloManager(uint256 _amount) external {
        require(
            userToManager[msg.sender] == address(0),
            "Only one manager is allowed per address"
        );
        require(_amount >= minFundingAmount, "Amount too small");
        address manager = Clones.clone(managerImplementation);
        ISiloManager(manager).initialize(address(this), msg.sender);
        isManager[manager] = true;
        userToManager[msg.sender] = manager;

        uint256 beforeBalance = ERC677Link.balanceOf(address(this));
        //swap ERC20 Link if need be
        if (ERC677Link.balanceOf(msg.sender) < _amount) {
            //if caller does not own enough ERC677 Link, then swap ERC20 Link for ERC677 Link
            SafeERC20.safeTransferFrom(
                ERC20Link,
                msg.sender,
                address(this),
                _amount
            );
            ERC20Link.approve(PEGSWAP_ADDRESS, _amount);
            PegSwap.swap(_amount, ERC20_LINK_ADDRESS, ERC677_LINK_ADDRESS);
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(ERC677_LINK_ADDRESS),
                msg.sender,
                address(this),
                _amount
            );
        }
        //create upkeep
        string memory name = string(
            abi.encodePacked("Silo Manager: ", Strings.toString(managerCount))
        );
        uint96 amount = uint96(ERC677Link.balanceOf(address(this)) -  beforeBalance);
        bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR,
            name,
            hex"",
            manager,
            GAS_LIMIT,
            address(this),
            hex"",
            amount,
            SOURCE,
            address(this)
        );

        (State memory state, , ) = Registry.getState();
        uint256 numUpkeeps = state.numUpkeeps;
        ERC677Link.transferAndCall(REGISTRAR_ADDRESS, amount, data);
        managerCount += 1;
        (state, , ) = Registry.getState();

        if(state.numUpkeeps > numUpkeeps){
            uint256[] memory ids = Registry.getActiveUpkeepIDs(numUpkeeps,0);
            uint256 maxCount = ids.length;
            for (uint256 idx = 0; idx < maxCount; idx++) {
                uint256 id = ids[idx];
                (address target, , , , , , , ) = Registry.getUpkeep(id);
                if(target == manager){
                    ISiloManager(manager).setUpkeepId(id);
                    break;
                }
            }
        }
    }

    function checkRegistryState()
        external
        view
        returns (
            State memory state,
            Config memory config,
            address[] memory keepers
        )
    {
        (state, config, keepers) = Registry.getState();
    }

    function fundManager(address _user, uint256 _amount) external {
        address manager = userToManager[_user];
        require(manager != address(0), "User does not have a manager");
        uint256 id = ISiloManager(manager).upkeepId();
        require(id != 0, "Manager not approved");
        //swap ERC20 Link if need be
        if (ERC677Link.balanceOf(msg.sender) < _amount) {
            //if caller does not own enough ERC677 Link, then swap ERC20 Link for ERC677 Link
            SafeERC20.safeTransferFrom(
                ERC20Link,
                msg.sender,
                address(this),
                _amount
            );
            ERC20Link.approve(PEGSWAP_ADDRESS, _amount);
            PegSwap.swap(_amount, ERC20_LINK_ADDRESS, ERC677_LINK_ADDRESS);
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(ERC677_LINK_ADDRESS),
                msg.sender,
                address(this),
                _amount
            );
        }
        ERC677Link.approve(getKeeperRegistry(), _amount);
        Registry.addFunds(id, uint96(_amount));
    }


    function setUserRiskBuffer(uint96 _buffer) external  {
        require(_buffer >= 10000, "Risk Buffer not valid");
        address manager = userToManager[msg.sender];
        require(manager != address(0), "User does not have a manager");
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        require(id != 0, "Manager not approved");
        Manager.setCustomRiskBuffer(_buffer);
    }

    function setUserRejoinBuffer(uint96 _buffer) external {
        require(_buffer >= 10000, "Rejoin Buffer not valid");
        address manager = userToManager[msg.sender];
        require(manager != address(0), "User does not have a manager");
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        require(id != 0, "Manager not approved");
        Manager.setCustomRejoinBuffer(_buffer);
    }

    function getKeeperRegistry() public view returns (address) {
        return alphaOrBeta ? alphaRegistry : betaRegistry;
    }

    function getOldKeeperRegistry() public view returns (address) {
        return alphaOrBeta ? betaRegistry : alphaRegistry;
    }

    function getMinimumUpkeepBalance(address _user)
        public
        view
        returns (uint96)
    {
        address manager = userToManager[_user];
        require(manager != address(0), "User does not have a manager");
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        require(id != 0, "Manager not approved");
        return
            (Registry.getMinBalanceForUpkeep(id) * Manager.getRiskBuffer()) /
            uint96(10000);
    }

    function sponsorUpkeep() external {
        require(needSponsor.length() > 0, "Nothing to sponsor");
        uint256 id = needSponsor.at(0);
        (
            ,
            ,
            ,
            uint96 balance,
            ,
            ,
            uint256 maxValidBlock,

        ) = KeeperRegistryInterface(getOldKeeperRegistry()).getUpkeep(id);
        require(
            block.number > maxValidBlock,
            "Gravity Finance: Max Valid Block not reached yet"
        );
        needSponsor.remove(id); //remove upkeep id from needSponsor
        uint256 bal = uint256(balance);
        uint256 reward = (bal * sponsorFee) / 10000;
        KeeperRegistryInterface(getOldKeeperRegistry()).withdrawFunds(
            id,
            address(this)
        );
        uint256 fundsToReturn = bal - reward;
        ERC677Link.approve(getKeeperRegistry(), fundsToReturn);
        KeeperRegistryInterface(getKeeperRegistry()).addFunds(
            id,
            uint96(fundsToReturn)
        );
        ERC677Link.transfer(msg.sender, reward);
    }

    function getUpkeepBalance(address _user) external view returns (uint96) {
        address manager = userToManager[_user];
        if (manager == address(0)) {
            //_user doesn't have a manager
            return 0;
        }
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        (address target, , , uint96 balance, , , , ) = Registry.getUpkeep(id);
        if (target != address(manager)) {
            //upkeep is not approved
            return 0;
        }
        return balance;
    }

    function managerApproved(address _user) external view returns (bool) {
        address manager = userToManager[_user];
        if(manager == address(0)){
            return false;
        }
        // require(
        //     manager != address(0),
        //     "Gravity Finance: _user does not own a manger"
        // );
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        (address target, , , , , , uint64 maxValidBlocknumber, ) = Registry
            .getUpkeep(id);
        bool isAcitve = maxValidBlocknumber == UINT64_MAX;
        return target == manager && isAcitve;
    }

    function managerCanceled(address _user) external view returns (bool) {
        address manager = userToManager[_user];
        require(
            manager != address(0),
            "Gravity Finance: _user does not own a manger"
        );
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        (, , , , , , uint64 maxValidBlocknumber, ) = Registry.getUpkeep(id);
        bool canceled = maxValidBlocknumber != UINT64_MAX &&
            maxValidBlocknumber != 0;
        return canceled;
    }

    function cancelUpkeep() external {
        require(!migrate, "Cannot cancel upkeeps while migration is active");
        address manager = userToManager[msg.sender];
        require(
            manager != address(0),
            "Gravity Finance: _user does not own a manger"
        );

        //enforce safety checks
        uint256 siloID;
        ISilo Silo;
        ISiloFactory SiloFactory = ISiloFactory(siloFactory);
        for (uint256 i = 0; i < SiloFactory.balanceOf(msg.sender); i++) {
            siloID = SiloFactory.tokenOfOwnerByIndex(msg.sender, i);
            Silo = ISilo(SiloFactory.siloMap(siloID));
            if (Silo.highRiskAction()) {
                require(
                    !Silo.deposited(),
                    "Silo should not be deposited"
                );
            }
        }

        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        (, , , , , , uint256 maxValidBlock, ) = Registry.getUpkeep(id);
        require(
            maxValidBlock == UINT64_MAX,
            "Gravity Finance: Upkeep already cancelled"
        );
        //remove upkeep from sets if in sets
        if (upkeepSetAlpha.contains(id)) {
            upkeepSetAlpha.remove(id);
        } else if (upkeepSetBeta.contains(id)) {
            upkeepSetBeta.remove(id);
        }
        if (needSponsor.contains(id)) {
            needSponsor.remove(id);
        }
        Registry.cancelUpkeep(id);
    }

    //have it swap ERC677 Link to ERC20
    function withdrawFundsFromCanceled(bool _linkType) external {
        address manager = userToManager[msg.sender];
        userToManager[msg.sender] = address(0); //user no longer has an upkeep after this function so remove the manager
        require(
            manager != address(0),
            "Gravity Finance: _user does not own a manger"
        );
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        (, , , uint96 balance, , , uint256 maxValidBlock, ) = Registry
            .getUpkeep(id);
        require(
            block.number > maxValidBlock,
            "Gravity Finance: Max Valid Block not reached yet"
        );
        //remove upkeep from sets if in sets
        if (upkeepSetAlpha.contains(id)) {
            upkeepSetAlpha.remove(id);
        } else if (upkeepSetBeta.contains(id)) {
            upkeepSetBeta.remove(id);
        }
        if (needSponsor.contains(id)) {
            needSponsor.remove(id);
        }
        if (_linkType) {
            //user wants erc677 link
            Registry.withdrawFunds(id, msg.sender);
        } else {
            //user wants erc20 link
            uint256 beforeBalance =  ERC677Link.balanceOf(address(this));
            Registry.withdrawFunds(id, address(this));
            uint256 currentBalance =  ERC677Link.balanceOf(address(this));
            ERC677Link.approve(PEGSWAP_ADDRESS, uint256(balance));
            PegSwap.swap(
                currentBalance - beforeBalance,
                ERC677_LINK_ADDRESS,
                ERC20_LINK_ADDRESS
            );
            SafeERC20.safeTransfer(ERC20Link, msg.sender, currentBalance - beforeBalance);
        }
    }

    function fundsWithdrawable(address _user) external view returns (bool) {
        address manager = userToManager[_user];
        require(
            manager != address(0),
            "Gravity Finance: _user does not own a manger"
        );
        ISiloManager Manager = ISiloManager(manager);
        uint256 id = Manager.upkeepId();
        require(id > 0, "Manager not approved");
        (, , , , , , uint256 maxValidBlock, ) = Registry.getUpkeep(id);
        return block.number > maxValidBlock;
    }

    function canCancelUpkeep(address _user) external view returns (bool) {
        uint256 siloID;
        ISilo Silo;
        ISiloFactory SiloFactory = ISiloFactory(siloFactory);

        for (uint256 i = 0; i < SiloFactory.balanceOf(_user); i++) {
            siloID = SiloFactory.tokenOfOwnerByIndex(_user, i);
            Silo = ISilo(SiloFactory.siloMap(siloID));
            if (Silo.highRiskAction()) {
                if(Silo.deposited()){
                    return false;
                }
            }
        }
        return true;
    }

    function getUpkeep(uint256 _id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber,
            uint96 amountSpent
        )
    {
        (
            target,
            executeGas,
            checkData,
            balance,
            lastKeeper,
            admin,
            maxValidBlocknumber,
            amountSpent
        ) = Registry.getUpkeep(_id);
    }

    function getTarget(uint256 _id) external view returns (address target) {
        (target, , , , , , , ) = Registry.getUpkeep(_id);
    }

    function getBalance(uint256 _id) external view returns (uint96 balance) {
        (, , , balance, , , , ) = Registry.getUpkeep(_id);
    }

    function getMinBalance(uint256 _id) external view returns (uint96 balance) {
        balance = Registry.getMinBalanceForUpkeep(_id);
    }

    function getOldMaxValidBlockAndBalance(uint256 _id)
        external
        view
        returns (uint256 mvb, uint96 bal)
    {
        (, , , bal, , , mvb, ) = KeeperRegistryInterface(getOldKeeperRegistry())
            .getUpkeep(_id);
    }

    function getUsersUpkeepId(address _user)
        external
        view
        returns (uint256 id)
    {
        address manager = userToManager[_user];
        require(
            manager != address(0),
            "Gravity Finance: _user does not own a manger"
        );
        ISiloManager Manager = ISiloManager(manager);
        id = Manager.upkeepId();
    }

    function currentUpkeepToMigrate() public view returns (uint256) {
        if (alphaOrBeta) {
            //moving from beta to alpha
            return upkeepSetBeta.at(0); //remove id  from alpha set
        } else {
            //moving from alpha to beta
            return upkeepSetAlpha.at(0);
        }
    }

    function adminCancelManagerUpkeep(uint256 id) external onlyOwner {
        (, , , , , , uint256 maxValidBlock, ) = Registry.getUpkeep(id);
        require(
            maxValidBlock == UINT64_MAX,
            "Gravity Finance: Upkeep already cancelled"
        );
        //remove upkeep from sets if in sets
        if (upkeepSetAlpha.contains(id)) {
            upkeepSetAlpha.remove(id);
        } else if (upkeepSetBeta.contains(id)) {
            upkeepSetBeta.remove(id);
        }
        if (needSponsor.contains(id)) {
            needSponsor.remove(id);
        }
        Registry.cancelUpkeep(id);
    }

    //have it swap ERC677 Link to ERC20
    function adminWithdrawFundsOfManager(
        bool _linkType,
        uint256 id,
        address to
    ) external onlyOwner {
        (, , , uint96 balance, , , uint256 maxValidBlock, ) = Registry
            .getUpkeep(id);
        require(
            block.number > maxValidBlock,
            "Gravity Finance: Max Valid Block not reached yet"
        );
        //remove upkeep from sets if in sets
        if (upkeepSetAlpha.contains(id)) {
            upkeepSetAlpha.remove(id);
        } else if (upkeepSetBeta.contains(id)) {
            upkeepSetBeta.remove(id);
        }
        if (needSponsor.contains(id)) {
            needSponsor.remove(id);
        }
        if (_linkType) {
            //user wants erc677 link
            Registry.withdrawFunds(id, to);
        } else {
            //user wants erc20 link
            uint256 beforeBalance =  ERC677Link.balanceOf(address(this));
            Registry.withdrawFunds(id, address(this));
            uint256 currentBalance =  ERC677Link.balanceOf(address(this));
            ERC677Link.approve(PEGSWAP_ADDRESS, uint256(balance));
            PegSwap.swap(
                currentBalance - beforeBalance,
                ERC677_LINK_ADDRESS,
                ERC20_LINK_ADDRESS
            );
            SafeERC20.safeTransfer(ERC20Link, msg.sender, currentBalance - beforeBalance);
        }
    }

    function setSiloManagerKeepId(address manager, uint256 id)
        external
        onlyOwner
    {
        ISiloManager(manager).setUpkeepId(id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloManager{
    function createUpkeep(address _owner, uint _amount) external;
    function setUpkeepId(uint id) external;
    function owner() external view returns(address);
    function upkeepId() external view returns(uint);
    function initialize(address _mangerFactory, address _owner) external;
    function getRiskBuffer() external view returns(uint96);
    function checkUpkeep(bytes calldata checkData) external returns(bool,bytes memory);

    function setCustomRiskBuffer(uint96 _buffer) external ;

    function setCustomRejoinBuffer(uint96 _buffer) external;

    function getRejoinBuffer() external view returns(uint96);
    
    function getMinBuffers() external view returns(uint96 minRisk , uint96 minRejoin);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @ownerLinkBalance withdrawable balance of LINK by contract owner
 * @numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;
  
  function withdrawFunds(uint256 id, address to) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);

    function strategyInputs(uint _id) external view returns(address[4] memory inputs);

    function strategyActions(uint _id) external view returns(address[] memory actions);

    function strategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);

    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);

    function catalogue(uint _type) external view returns(string[] memory);
    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);
    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(uint256 siloID) external;

    function Deposit() external;

    function Withdraw(uint256 _requestedOut) external;

    function Maintain() external;

    function ExitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[4] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function strategyCategory() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[4] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible) ;

    function adjustTokenMinimums(address _token, uint _minimum) external;

    function getWithdrawLimitSiloInfo()
        external
        view
        returns (
            bool isLimit,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}