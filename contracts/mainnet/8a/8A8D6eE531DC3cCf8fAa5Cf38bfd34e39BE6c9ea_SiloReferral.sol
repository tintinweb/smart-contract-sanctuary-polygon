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

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IAction.sol";
import "../../interfaces/ISiloFactory.sol";

contract SiloReferral is Ownable {
    address public siloFactory;

    uint256 public referralShare = 1000;

    struct ReferralCode {
        uint256 share;
        address recipient;
    }

    mapping(bytes32 => ReferralCode) public referralCodes;

    mapping(address => ReferralCode) public siloToReferrer;

    event RegisterReferral(string referral, address recipient, uint256 share);

    event UpdateRecipient(
        string referral,
        address oldRecipient,
        address newRecipient
    );
    event UpdateShare(string referral, uint256 oldShare, uint256 newShare);

    constructor(address _siloFactory) {
        siloFactory = _siloFactory;
    }

    modifier onlyFactory() {
        require(msg.sender == siloFactory, "not factory");
        _;
    }

    modifier onlySilo() {
        require(ISiloFactory(siloFactory).isSilo(msg.sender), "not silo");
        _;
    }

    function existCode(bytes32 _code) external view returns (bool) {
        ReferralCode memory code = referralCodes[_code];
        return code.recipient != address(0);
    }

    function approvedCode(bytes32 _code) external view returns (bool) {
        ReferralCode memory code = referralCodes[_code];
        return code.share > 0;
    }
    function stringTo(string memory source) public pure returns(bytes32 result) {
        result =  bytes32(abi.encodePacked(source));
    }


    function registerReferral(
        string memory referral,
        address _recipient,
        uint256 _share
    ) external onlyOwner {
        bytes32 _code = bytes32(abi.encodePacked(referral));
        require(_code != bytes32(0), "invalid code");
        require(_recipient != address(0), "wrong recipient");
        ReferralCode memory code = referralCodes[_code];
        require(code.recipient == address(0), "code already exists");

        referralCodes[_code] = ReferralCode({
            share: _share,
            recipient: _recipient
        });

        emit RegisterReferral(referral, _recipient, _share);
    }

    function udpateRecipient(string memory referral, address _recipient)
        external
        onlyOwner
    {
        bytes32 _code = bytes32(abi.encodePacked(referral));
        require(_code != bytes32(0), "invalid code");
        require(_recipient != address(0), "invalid recipient");
        ReferralCode storage code = referralCodes[_code];
        require(code.recipient != _recipient, "same recipient");
        address oldRecipient = code.recipient;
        code.recipient = _recipient;

        emit UpdateRecipient(referral, oldRecipient, _recipient);
    }

    function udpateReferralShare(string memory referral, uint256 _share) external onlyOwner {
        bytes32 _code = bytes32(abi.encodePacked(referral));
        require(_code != bytes32(0), "invalid code");
        require(_share < 10000, "wrong share amount");
        ReferralCode storage code = referralCodes[_code];
        require(code.share != _share, "same share");
        uint256 oldShare = code.share;
        code.share = _share;

        emit UpdateShare(referral, oldShare, _share);
    }

    /***************************************external onlyOwner *************************************/
    function updateSiloFactory(address _siloFactory) external onlyOwner {
        siloFactory = _siloFactory;
    }

    function updateShare(uint256 _share) external onlyOwner {
        require(_share < 10000, "wrong share amount");
        referralShare = _share;
    }

    function setSiloReferrer(address _silo, bytes32 _code) external onlySilo {
        if (_code != bytes32(0)) {
            ReferralCode memory code = referralCodes[_code];
            if (code.recipient == address(0)) {
                address referrer = address(uint160(uint256(_code)));
                if (referrer != address(0)) {
                    ISiloFactory factory = ISiloFactory(siloFactory);

                    address siloOwner = factory.ownerOf(
                        factory.siloToId(_silo)
                    );
                    if (siloOwner != referrer) {
                        siloToReferrer[_silo] = ReferralCode({
                            share: referralShare,
                            recipient: referrer
                        });
                    }
                }
            } else {
                siloToReferrer[_silo] = ReferralCode({
                    share: code.share,
                    recipient: code.recipient
                });
            }
        }
    }

    function siloReferralInfo(address _silo)
        public
        view
        returns (uint256, address)
    {
        return (siloToReferrer[_silo].share, siloToReferrer[_silo].recipient);
    }
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

    function checkMaintain(bytes memory configuration)
        external
        view
        returns (bool);

    function checkUpkeep(bytes memory configuration)
        external
        view
        returns (bool);

    function extraInfo(bytes memory configuration)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function validateConfig(bytes memory configData)
        external
        view
        returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(address _action)
        external
        view
        returns (string memory actionName, uint256[4] memory fees);

    function showBalances(address _silo, bytes memory _configurationData)
        external
        view
        returns (ActionBalance memory);

    function showDust(address _silo, bytes memory _configurationData)
        external
        view
        returns (address[] memory, uint256[] memory);

    function vaultInfo(address _silo, bytes memory configuration)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function actionValid(bytes memory _configurationData)
        external
        view
        returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(address _silo, address _manager)
        external
        view
        returns (bool);

    function setFactory(address _siloFactory) external;
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
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}