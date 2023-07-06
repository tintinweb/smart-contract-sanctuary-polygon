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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "../../interfaces/IAction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ISiloManagerFactory.sol";
// import "../../interfaces/ISiloManager.sol";
// import {KeeperRegistryInterface} from "../../chainlink/interfaces/KeeperRegistryInterface.sol";
import "./V2/interfaces/IAutoCreator.sol";
struct SiloInfo {
    uint256 id;
    uint256 autoType;
    address siloAddress;
    string strategyName;
    uint256 strategyCategory;
    string siloName;
    uint256 siloDelay;
    address[] actions;
    bytes[] configurationData;
    string[5] inputTokenTypes;
    string[] makeups;
    bool isHighRisk;
    bool deposited;
    Statuses status;
    string state;
    address[5] inputs;
    uint256 main;
}

struct StrategyInfo {
    string strategyName;
    uint256 strategyCategory;
    address[] actions;
    bytes[] configurationData;
    string[5] inputTokenTypes;
    string[] makeups;
    bool isHighRisk;
    address[5] inputs;
    uint256 main;
    string[] feeNames;
    uint256[] fees;
}

contract SiloFactoryUIHelper is Ownable {
    address public siloFactory;
    ISiloFactory SiloFactory;
    mapping(uint256 => string[5]) public categoryInputTypes;

    mapping(uint256 => bool) public isHighRiskCategory;
    uint256[] public availableCategories;
    uint256 public warningMultiplier = 20000;
    uint64 private constant UINT64_MAX = 2 ** 64 - 1;

    constructor(address _siloFactory) {
        siloFactory = _siloFactory;
        SiloFactory = ISiloFactory(_siloFactory);
        categoryInputTypes[0] = ["main", "zap", "zap", "zap", "zap"];
        categoryInputTypes[1] = ["main", "zap", "zap", "zap", "debt"];
        categoryInputTypes[2] = ["main", "zap", "zap", "zap", "zap"];

        isHighRiskCategory[1] = true;

        availableCategories.push(0);
        availableCategories.push(1);
        availableCategories.push(2);
    }

    /***************************************external onlyOwner *************************************/
    function updateSiloFactory(address _siloFactory) external onlyOwner {
        siloFactory = _siloFactory;
        SiloFactory = ISiloFactory(_siloFactory);
    }

    function setCategoryInputTypes(
        uint256 _category,
        string[5] memory _types
    ) external onlyOwner {
        categoryInputTypes[_category] = _types;
    }

    function changeWarningMultiplier(uint256 _multiplier) external onlyOwner {
        warningMultiplier = _multiplier;
    }

    function addCategories(uint256 _category) external onlyOwner {
        availableCategories.push(_category);
    }

    /***************************************external state mutative *************************************/

    function getLastTimeMaintained(
        uint256 siloID
    ) external view returns (uint256) {
        return ISilo(siloMap(siloID)).lastTimeMaintained();
    }

    function getTimeToNextMaintain(
        uint256 siloID
    ) external view returns (uint256 time) {
        time = block.timestamp - ISilo(siloMap(siloID)).lastTimeMaintained();
        uint256 delay = ISilo(siloMap(siloID)).siloDelay();
        if (time < delay) {
            time = delay - time;
        } else {
            time = 0;
        }
    }

    //get the action stack using the strategy name
    function getActionStackWithName(
        string memory _strategyName
    )
        external
        view
        returns (
            address[5] memory inputs,
            address[] memory actions,
            bytes[] memory configurationData
        )
    {
        uint256 id = SiloFactory.strategyName(_strategyName);
        inputs = SiloFactory.getStrategyInputs(id);
        actions = SiloFactory.getStrategyActions(id);
        configurationData = SiloFactory.getStrategyConfigurationData(id);
    }

    /**
     * @dev returns an error array
     * if errors = [0,0] no errors were found
     * if errors = [A,A] and A != 0, then there is an erorr with validateConfig locaetd at index A-1 in the _configurationData Array
     * if errors = [A,B] and A != B, then there is an input/output mismatch located between indexes A-1 and B-1 in the _configurationData array
     */
    function validateStrategyWithStack(
        address[5] memory _inputs,
        address[] memory _actions,
        bytes[] memory _configurationData
    ) external view returns (uint256[2] memory errors) {
        require(
            _actions.length == _configurationData.length,
            "Gravity: Actions/Configuration Lengths do not match"
        );
        address[5] memory input = _inputs;
        address[5] memory output;
        address[5] memory tmp;
        uint256 actionCount = _actions.length;
        for (uint256 i = 0; i < actionCount; i++) {
            if (!IAction(_actions[i]).validateConfig(_configurationData[i])) {
                errors[0] = i + 1;
                errors[1] = i + 1;
                break;
            }

            if (i == actionCount - 1) {
                (output) = abi.decode(_configurationData[i], (address[5]));
            } else {
                (output, tmp) = abi.decode(
                    _configurationData[i],
                    (address[5], address[5])
                );
            }

            for (uint256 j = 0; j < 5; j++) {
                if (input[j] != output[j]) {
                    errors[0] = i;
                    errors[1] = i + 1;
                    break;
                }
            }
            if (errors[0] != 0 && errors[1] != 0) {
                break;
            } //break out of for loop if error was found
            input = tmp;
        }
    }

    function viewConfigMakeupForStack(
        address[] memory actions
    ) public view returns (string[] memory makeups) {
        makeups = new string[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            makeups[i] = viewConfigMakeupForAction(actions[i]);
        }
    }

    // function getFeeInfo(address _action) external view returns(uint fee, address recipient){
    //     uint tier = SiloFactory.getTier(msg.sender);
    //     if(SiloFactory.useCustom(_action)){
    //         return (SiloFactory.getFeeList(_action)[tier], SiloFactory.feeRecipient(_action));
    //     }
    //     else{
    //         return (SiloFactory.defaultFeeList()[tier], SiloFactory.defaultRecipient());
    //     }
    // }

    // function getFeeInfoNoTier(address _action) external view returns(uint[4] memory){
    //     if(SiloFactory.useCustom(_action)){
    //         return SiloFactory.getFeeList(_action);
    //     }
    //     else{
    //         return SiloFactory.defaultFeeList();
    //     }
    // }

    // function managerApproved(address _user) public view returns(bool){
    //     return ISiloManagerFactory(SiloFactory.managerFactory()).managerApproved(_user);
    // }

    // function managerExists(address _user) public view returns(bool){
    //     address manager = ISiloManagerFactory(SiloFactory.managerFactory()).userToManager(_user);
    //     return manager != address(0);
    // }

    function showActionStackFeeInfo(
        address[] memory _implementations
    ) public view returns (string[] memory, uint256[] memory) {
        uint256[4] memory actionFees;
        string memory name;
        uint256[] memory fees = new uint256[](_implementations.length * 4);
        string[] memory names = new string[](_implementations.length);
        for (uint256 i = 0; i < _implementations.length; i++) {
            (name, actionFees) = IAction(_implementations[i]).showFee(
                _implementations[i]
            );
            names[i] = name;
            for (uint256 j = 0; j < 4; j++) {
                fees[i * 4 + j] = actionFees[j];
            }
        }
        return (names, fees);
    }

    function getCategoryInputTypes(
        uint256 _category
    ) external view returns (string[5] memory) {
        return categoryInputTypes[_category];
    }

    /***************************************public state mutative *************************************/

    /***************************************public view *************************************/

    function getCategories() public view returns (uint256[] memory) {
        return availableCategories;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getSiloInputAndOutput(
        uint256 siloId
    ) public view returns (address[5] memory input, address[5] memory output) {
        bytes memory config = ISilo(siloMap(siloId)).getConfig();
        (input, output) = abi.decode(config, (address[5], address[5]));
    }

    function siloMap(uint256 _id) public view returns (address) {
        return SiloFactory.siloMap(_id);
    }

    function siloToId(address _silo) public view returns (uint256) {
        return SiloFactory.siloToId(_silo);
    }

    // function getTier(address silo) public view returns(uint){
    //     return SiloFactory.getTier(silo);
    // }

    function viewConfigMakeupForAction(
        address action
    ) public view returns (string memory makeup) {
        makeup = IAction(action).getMetaData();
    }

    function viewSiloStrategyMetaData(
        uint256 siloID
    ) public view returns (SiloInfo memory info) {
        // address _user = SiloFactory.ownerOf(siloID);
        ISilo silo = ISilo(SiloFactory.siloMap(siloID));

        if (address(silo) != address(0)) {
            (address[] memory actions, bytes[] memory configData) = silo
                .viewStrategy();
            string[] memory makeups = viewConfigMakeupForStack(actions);

            info = SiloInfo({
                id: siloID,
                autoType: silo.autoType(),
                siloAddress: address(silo),
                strategyName: silo.strategyName(),
                strategyCategory: silo.strategyCategory(),
                siloName: silo.name(),
                siloDelay: silo.siloDelay(),
                actions: actions,
                makeups: makeups,
                configurationData: configData,
                inputTokenTypes: categoryInputTypes[silo.strategyCategory()],
                isHighRisk: silo.highRiskAction(),
                deposited: silo.deposited(),
                status: silo.status(),
                state: getState(siloID),
                inputs: silo.getInputTokens(),
                main: SiloFactory.mainActoins(silo.strategyName())
            });
        }
    }

    function showStrategyBalances(
        uint256 siloId
    ) external view returns (ActionBalance[] memory strategyBalances) {
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        IAction action;
        (address[] memory actions, bytes[] memory configData) = silo
            .viewStrategy();
        strategyBalances = new ActionBalance[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            action = IAction(actions[i]);
            strategyBalances[i] = action.showBalances(
                address(silo),
                configData[i]
            );
        }
    }

    function showBalancesInSiloWithRepeats(
        uint256 siloId
    ) external view returns (address[] memory, uint256[] memory) {
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        IAction action;
        (address[] memory actions, bytes[] memory configData) = silo
            .viewStrategy();
        address[] memory allTokens = new address[](actions.length * 2);
        uint256[] memory allBalances = new uint256[](actions.length * 2);
        uint256 index;
        (address[5] memory inputs, ) = getSiloInputAndOutput(siloId);
        {
            address[] memory tmpTokens;
            uint256[] memory tmpBalances;
            for (uint256 i = 0; i < actions.length; i++) {
                action = IAction(actions[i]);
                (tmpTokens, tmpBalances) = action.showDust(
                    address(silo),
                    configData[i]
                );
                for (uint256 j = 0; j < tmpTokens.length; j++) {
                    if (tmpBalances[j] > 0) {
                        allTokens[index] = tmpTokens[j];
                        allBalances[index] = tmpBalances[j];
                        index += 1;
                    }
                }
            }
        }

        address[] memory tokens = new address[](index + 5);
        uint256[] memory balances = new uint256[](index + 5);
        for (uint256 i = 0; i < index; i++) {
            //copy over dust tokens
            tokens[i] = allTokens[i];
            balances[i] = allBalances[i];
        }

        for (uint256 i = index; i < index + 5; i++) {
            if (inputs[i - index] == address(0)) {
                continue;
            }
            tokens[i] = inputs[i - index];
            balances[i] = IERC20(inputs[i - index]).balanceOf(address(silo));
        }
        return (tokens, balances);
    }

    function getExtraSiloInfo(
        uint256 siloId
    )
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        )
    {
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        return silo.getExtraSiloInfo();
    }

    function getVaultInfo(
        uint256 siloId
    )
        external
        view
        returns (
            uint256 vaultId,
            uint256 collateral,
            uint256 debt,
            uint256 cdr,
            uint256 debtCeil
        )
    {
        uint256 _vaultId;
        uint256 _collateral;
        uint256 _debt;
        uint256 _cdr;
        uint256 _debtCeil;

        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        IAction action;
        (address[] memory actions, bytes[] memory configData) = silo
            .viewStrategy();

        for (uint256 i; i < actions.length; ) {
            action = IAction(actions[i]);
            (_vaultId, _collateral, _debt, _cdr, _debtCeil) = action.vaultInfo(
                address(silo),
                configData[i]
            );
            vaultId += _vaultId;
            collateral += _collateral;
            debt += _debt;
            cdr += _cdr;
            debtCeil += _debtCeil;
            unchecked {
                i++;
            }
        }
    }

    // function depositAllowed(
    //     uint256 siloId
    // ) public view returns (bool possible) {
    //     ISilo silo = ISilo(SiloFactory.siloMap(siloId));
    //     address user = SiloFactory.ownerOf(siloId);

    //     ISiloManagerFactory factory = ISiloManagerFactory(
    //         SiloFactory.managerFactory()
    //     );
    //     address manager = factory.userToManager(user);
    //     if (address(silo) != address(0) && manager != address(0)) {
    //         ISiloManager Manager = ISiloManager(manager);
    //         uint256 id = Manager.upkeepId();
    //         if (id != 0) {
    //             uint256 currentBalance = factory.getUpkeepBalance(user);
    //             uint256 minimumBalance = factory.getMinBalance(id);
    //             uint256 riskAdjustedBalance = factory.getMinimumUpkeepBalance(
    //                 user
    //             );

    //             if (silo.highRiskAction()) {
    //                 //check that balance is above the riskadjusted minimum
    //                 possible = currentBalance > riskAdjustedBalance;
    //             } else {
    //                 possible = currentBalance > minimumBalance;
    //             }
    //         }
    //     }
    // }

    // function getAllStrategyInfo()
    //     external
    //     view
    //     returns (string[] memory names, uint256[] memory categories)
    // {
    //     names = new string[](SiloFactory.currentStrategyId() - 1);
    //     categories = new uint256[](SiloFactory.currentStrategyId() - 1);
    //     uint256 counter;
    //     string[] memory _names;
    //     for (uint256 i = 0; i < availableCategories.length; i++) {
    //         _names = SiloFactory.getCatalogue(i);
    //         for (uint256 j = 0; j < _names.length; j++) {
    //             names[counter] = _names[j];
    //             categories[counter] = availableCategories[i];
    //             counter++;
    //         }
    //     }
    // }

    function getStrategyInfo()
        external
        view
        returns (string[] memory names, StrategyInfo[] memory info)
    {
        info = new StrategyInfo[](SiloFactory.currentStrategyId() - 1);

        names = new string[](SiloFactory.currentStrategyId() - 1);

        uint256 counter;
        string[] memory _names;
        string memory _strategyName;
        for (uint256 i = 0; i < availableCategories.length; i++) {
            _names = SiloFactory.getCatalogue(availableCategories[i]);
            for (uint256 j = 0; j < _names.length; j++) {
                names[counter] = _names[j];

                _strategyName = _names[j];

                uint256 id = SiloFactory.strategyName(_strategyName);
                address[5] memory inputs = SiloFactory.getStrategyInputs(id);
                address[] memory actions = SiloFactory.getStrategyActions(id);
                bytes[] memory configurationData = SiloFactory
                    .getStrategyConfigurationData(id);

                string[] memory makeups = viewConfigMakeupForStack(actions);

                (
                    string[] memory feeNames,
                    uint256[] memory fees
                ) = showActionStackFeeInfo(actions);

                info[counter] = StrategyInfo({
                    strategyName: _strategyName,
                    strategyCategory: availableCategories[i],
                    actions: actions,
                    makeups: makeups,
                    configurationData: configurationData,
                    inputTokenTypes: categoryInputTypes[availableCategories[i]],
                    isHighRisk: isHighRiskCategory[availableCategories[i]],
                    inputs: inputs,
                    main: SiloFactory.mainActoins(_strategyName),
                    feeNames: feeNames,
                    fees: fees
                });

                counter++;
            }
        }
    }

    function getUserSilosInfo(
        address _user
    ) external view returns (SiloInfo[] memory info) {
        info = new SiloInfo[](SiloFactory.balanceOf(_user));
        uint256 id;
        for (uint256 i = 0; i < info.length; i++) {
            id = SiloFactory.tokenOfOwnerByIndex(_user, i);
            info[i] = viewSiloStrategyMetaData(id);
        }
    }

    function getSiloTokenMinimums(
        uint256 siloId
    )
        public
        view
        returns (uint256[5] memory tokenMinimums, address[5] memory inputs)
    {
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        inputs = silo.getInputTokens();

        for (uint256 i = 0; i < 5; i++) {
            tokenMinimums[i] = silo.tokenMinimum(inputs[i]);
        }
    }

    function getState(uint256 siloId) public view returns (string memory) {
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        // address user = SiloFactory.ownerOf(siloId);

        Statuses status = silo.getStatus();

        if (silo.isNew()) {
            return "New";
        }

        if (status == Statuses.DORMANT || !silo.deposited()) {
            return "Inactive";
        }
        // ISiloManagerFactory autoFactory = ISiloManagerFactory(
        //     SiloFactory.managerFactory()
        // );
        // AutoStatus autostatus = autoFactory.getAutoStatus(
        //     user,
        //     silo.autoType()
        // );
        // if (managerApproved(user, silo.autoType())) {
        //     ISiloManagerFactory factory = ISiloManagerFactory(
        //         SiloFactory.managerFactory()
        //     );
        //     address manager = factory.userToManager(user);
        //     if (manager != address(0)) {
        //         ISiloManager Manager = ISiloManager(manager);
        //         uint256 id = Manager.upkeepId();
        //         uint256 currentBalance = factory.getUpkeepBalance(user);
        //         uint256 minimumBalance = factory.getMinBalance(id);
        //         uint256 riskAdjustedBalance = factory.getMinimumUpkeepBalance(
        //             user
        //         );
        //         if (silo.highRiskAction()) {
        //             if (currentBalance < riskAdjustedBalance) {
        //                 return "Unmanaged";
        //             }
        //         } else if (currentBalance < minimumBalance) {
        //             return "Manual";
        //         }
        //     }
        // } else {
        //     if (silo.highRiskAction()) {
        //         return "Inactive";
        //     } else {
        //         return "Manual";
        //     }
        // }

        if (status == Statuses.UNWIND) {
            return "Unwind";
        }

        if (status == Statuses.PAUSED) {
            return "Paused";
        }

        if (status == Statuses.MANAGED) {
            if (silo.deposited()) {
                return "Active";
            }
        }

        return "Unknown";
    }

    // function managerApproved(
    //     address _user,
    //     uint256 _autoType
    // ) public view returns (bool check) {
    //     ISiloManagerFactory autoFactory = ISiloManagerFactory(
    //         SiloFactory.managerFactory()
    //     );
    //     address manager = autoFactory.userToManager(_user, _autoType);

    //     if (manager != address(0)) {
    //         address creator = autoFactory.getAutoCreator(_autoType);
    //         check = IAutoCreator(creator).managerApproved(_user);
    //     }

    //     return false;
    // }

    // function possibleRiskSilo(
    //     address _user,
    //     uint256 _autoType
    // ) public view returns (bool check) {
    //     ISiloManagerFactory autoFactory = ISiloManagerFactory(
    //         SiloFactory.managerFactory()
    //     );
    //     address _manager = autoFactory.userToManager(_user, _autoType);

    //     if (_manager != address(0)) {
    //         address creator = autoFactory.getAutoCreator(_autoType);
    //         check =
    //             IAutoCreator(creator).getAutoManagerBalance(_manager) >
    //             IAutoCreator(creator).getAutoManagerHighBalance(_manager);
    //     }
    // }

    function getUserAutoStatus(
        address _user
    )
        public
        view
        returns (uint256[] memory autoKeys, uint256[] memory possibles)
    {
        ISiloManagerFactory autoFactory = ISiloManagerFactory(
            SiloFactory.managerFactory()
        );

        uint size = autoFactory.getAutoTypesSize();

        possibles = new uint256[](size);
        autoKeys = new uint256[](size);

        for (uint i = 0; i < size; ) {
            (uint256 _autoType, ) = autoFactory.getAutoTypeAt(i);

            autoKeys[i] = _autoType;

            AutoStatus status = autoFactory.getAutoStatus(_user, _autoType);
            possibles[i] = uint256(status);

            unchecked {
                i++;
            }
        }
    }

    function getManagerStats(
        address _user
    ) public view returns (ManagerInfo[] memory infos) {
        ISiloManagerFactory autoFactory = ISiloManagerFactory(
            SiloFactory.managerFactory()
        );

        uint size = autoFactory.getAutoTypesSize();

        infos = new ManagerInfo[](size);
        for (uint i = 0; i < size; ) {
            (uint256 _autoType, address _creator) = autoFactory.getAutoTypeAt(
                i
            );

            address _manager = autoFactory.userToManager(_user, _autoType);

            infos[i] = IAutoCreator(_creator).getTotalManagerInfo(_manager);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ManagerInfo {
    address manager;
    uint256 upkeepId;
    uint256 currentBalance;
    uint256 minimumBalance;
    uint256 riskAdjustedBalance;
    uint96 riskBuffer;
    uint96 rejoinBuffer;
    uint96 minRisk;
    uint96 minRejoin;
    bool autoTopup;
    uint256 topupThreshold;
    bool fundsWithdrawable;
    bool managerCanceled;
}

interface IAutoCreator {
    function getAutoManagerHighBalance(
        address _manager
    ) external view returns (uint256);

    function getAutoManagerBalance(
        address _manager
    ) external view returns (uint256);

    function getAutoMinThreshold(
        address _manager
    ) external view returns (uint256);

    function managerApproved(address _user) external view returns (bool);

    function getTotalManagerInfo(
        address _manager
    ) external view returns (ManagerInfo memory info);

    function autoType() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance {
    uint256 collateral;
    uint256 debt;
    address collateralToken;
    address debtToken;
    uint256 collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction {
    function getConfig() external view returns (bytes memory config);

    function checkMaintain(
        bytes memory configuration
    ) external view returns (bool, uint256);

    function checkUpkeep(
        bytes memory configuration
    ) external view returns (bool);

    function extraInfo(
        bytes memory configuration
    ) external view returns (uint256[4] memory info);

    function validateConfig(
        bytes memory configData
    ) external view returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(
        address _action
    ) external view returns (string memory actionName, uint256[4] memory fees);

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view returns (ActionBalance memory);

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view returns (address[] memory, uint256[] memory);

    function vaultInfo(
        address _silo,
        bytes memory configuration
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function actionValid(
        bytes memory _configurationData
    ) external view returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(
        address _silo,
        address _manager
    ) external view returns (bool);

    function setFactory(address _siloFactory) external;
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
    function initialize(
        uint256 siloID,
        uint256 main,
        address factory,
        uint256 autoType
    ) external;

    function autoType() external view returns (uint256);

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function main() external view returns (uint256);

    function lastPid() external view returns (uint256);

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

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
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
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);

    function mainActoins(string memory strategyName) external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum AutoStatus {
    NOT,
    APPROVED,
    MANUAL,
    NORMAL,
    HIGH
}

interface ISiloManager {
    function createUpkeep(address _owner, uint _amount) external;

    function setUpkeepId(uint id) external;

    function owner() external view returns (address);

    function upkeepId() external view returns (uint);

    function initialize(
        address _mangerFactory,
        address _creator,
        address _owner
    ) external;

    function getRiskBuffer() external view returns (uint96);

    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool, bytes memory);

    function setCustomRiskBuffer(uint96 _buffer) external;

    function setCustomRejoinBuffer(uint96 _buffer) external;

    function getRejoinBuffer() external view returns (uint96);

    function getMinBuffers()
        external
        view
        returns (uint96 minRisk, uint96 minRejoin);

    function autoTopup() external view returns (bool);

    function addFundsThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AutoStatus} from "./ISiloManager.sol";

interface ISiloManagerFactory {
    function checkManager(
        address _owner,
        address _manager,
        uint256 _autoType
    ) external view returns (bool);

    function userToManager(
        address _user,
        uint256 _autoType
    ) external view returns (address);

    function managerCount(uint256 _autoType) external view returns (uint256);

    function siloFactory() external view returns (address);

    function riskBuffer() external view returns (uint96);

    function rejoinBuffer() external view returns (uint96);

    function bufferPerSilo() external view returns (uint96);

    function getAutoCreator(uint256 _autoType) external view returns (address);

    function getAutoTypesSize() external view returns (uint256);

    function getAutoTypeAt(
        uint256 index
    ) external view returns (uint256 autoType, address creator);

    function getAutoStatus(
        address _user,
        uint256 _autoType
    ) external view returns (AutoStatus);
}