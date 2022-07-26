// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
pragma solidity 0.8.15;

error ForceNFTControlUserAlreadyReceived();
error ForceNFTControlTooConditionsNotMet();
error ForceNFTControlNotEnoughEnergy();
error ForceNFTControlWrongAmountNFTForMerge();
error ForceNFTControlWrongNFTLevel();
error ForceNFTControlThisLevelNFTMoreMax();
error ForceNFTControlNotEnoughValuesInArray(uint256 needLengthArray);
error ForceNFTControlNotHundredPercent();
error ForceNFTControlLengthAmountArrayIsNotCorrect();
error ForceNFTControlThisNameIsEmpty();
error ForceNFTControlSenderNotOwnerNFT(uint256 level, uint256 id);
error ForceNFTControlNFTCreatedAfterDistribution(uint256 _level, uint256 id);
error ForceNFTControlThereWasNoDistribution();
error ForceNFTControlNFTRewarded(uint256 _level, uint256 idNFT);
error ForceNFTDistributionAmountMoreThanBalance();
error ForceNFTNoRewardsForThisLevel(uint256 _level);
error ForceNFTControlNotEqualLengthArrays();

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IForceNFT.sol";
import "./interfaces/IControl.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IMetaProject.sol";
import "./interfaces/IEnergyCoin.sol";
import "./libraries/FixedPointMath.sol";

contract Control is Ownable, IControl {
    using FixedPointMath for uint256;

    mapping(address => bool) public alreadyReceivedEmptyNFT;

    mapping(uint256 => uint256) public override getFactorForEnergyTokens;

    mapping(uint256 => uint256) public requeredLevels;

    mapping(uint256 => uint256) public nftIndexes;
    //idDistribution -> level -> info
    mapping(uint256 => mapping(uint256 => Distribution)) public distributions;
    //idDistribution -> level -> idNFT -> bool
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) public nftRewarded;
    mapping(uint256 => uint256) public override getShareForLevelFromPool;

    uint256 public override getAmontNFTForMerge;
    uint256 public override getPriceUpToFirstLevel;
    uint256 public override getPriceFirstEmptyNFT;

    uint256 public indexNextDistribution;

    IRegistry public registry;

    constructor(address _registry) {
        registry = IRegistry(_registry);

        getAmontNFTForMerge = 3;
        getPriceUpToFirstLevel = 3500 ether;
        getPriceFirstEmptyNFT = 350 ether;

        getShareForLevelFromPool[1] = 0.1 ether;
        getShareForLevelFromPool[2] = 0.11 ether;
        getShareForLevelFromPool[3] = 0.12 ether;
        getShareForLevelFromPool[4] = 0.13 ether;
        getShareForLevelFromPool[5] = 0.14 ether;
        getShareForLevelFromPool[6] = 0.15 ether;
        getShareForLevelFromPool[7] = 0.25 ether;
    }

    function getEmptyNFT(uint256[] memory amounts) external override returns (uint256) {
        if (alreadyReceivedEmptyNFT[msg.sender]) {
            revert ForceNFTControlUserAlreadyReceived();
        }
        if (amounts.length != registry.getAmountMetaProject()) {
            revert ForceNFTControlLengthAmountArrayIsNotCorrect();
        }
        uint256 amount;
        uint256 tempPrice = getPriceFirstEmptyNFT;
        for (uint256 i = 0; i < amounts.length; i++) {
            IMetaProject metaProject = IMetaProject(registry.getMetaProject(i));
            IEnergyCoin energyCoin = IEnergyCoin(registry.getEnergyToken(i));
            uint256 energyConversionFactor = getFactorForEnergyTokens[registry.getIndexProject(i)];
            if (metaProject.getLevelForNFT(msg.sender) < requeredLevels[registry.getIndexProject(i)]) {
                revert ForceNFTControlTooConditionsNotMet();
            }
            amount = amounts[i].mul(energyConversionFactor);
            if (amount < tempPrice) {
                IEnergyCoin(energyCoin).burn(msg.sender, amounts[i]);
                tempPrice -= amount;
            } else {
                IEnergyCoin(energyCoin).burn(msg.sender, tempPrice.div(energyConversionFactor));
                tempPrice = 0;
                break;
            }
        }
        if (tempPrice != 0) {
            revert ForceNFTControlNotEnoughEnergy();
        }
        alreadyReceivedEmptyNFT[msg.sender] = true;
        return giveNFT(msg.sender, 0);
    }

    function levelUpEmptyNFT(uint256 id, uint256[] memory amounts) external override returns (uint256[] memory) {
        IForceNFT nft = IForceNFT(registry.getForceNFT(0));
        if (nft.ownerOf(id) != msg.sender) {
            revert ForceNFTControlSenderNotOwnerNFT(0, id);
        }
        if (amounts.length != registry.getAmountMetaProject()) {
            revert ForceNFTControlLengthAmountArrayIsNotCorrect();
        }
        uint256 amount;
        uint256 tempPrice = getPriceUpToFirstLevel;
        for (uint256 i = 0; i < amounts.length; i++) {
            IEnergyCoin energyCoin = IEnergyCoin(registry.getEnergyToken(i));
            uint256 energyConversionFactor = getFactorForEnergyTokens[registry.getIndexProject(i)];
            amount = amounts[i].mul(energyConversionFactor);
            if (amount < tempPrice) {
                IEnergyCoin(energyCoin).burn(msg.sender, amounts[i]);
                tempPrice -= amount;
            } else {
                IEnergyCoin(energyCoin).burn(msg.sender, tempPrice.div(energyConversionFactor));
                tempPrice = 0;
                break;
            }
        }
        if (tempPrice != 0) {
            revert ForceNFTControlNotEnoughEnergy();
        }
        burnNFT(0, id);
        uint256[] memory newNFTs = new uint256[](2);
        newNFTs[0] = giveNFT(msg.sender, 1);
        newNFTs[1] = giveNFT(msg.sender, 0);
        return newNFTs;
    }

    function mergeNFT(uint256 _level, uint256[] memory idNFT) external override returns (uint256) {
        if (_level == 0 || _level >= registry.getMaxLvlNFT()) {
            revert ForceNFTControlWrongNFTLevel();
        }
        if (idNFT.length != getAmontNFTForMerge) {
            revert ForceNFTControlWrongAmountNFTForMerge();
        }
        IForceNFT nft = IForceNFT(registry.getForceNFT(_level));
        for (uint256 i = 0; i < idNFT.length; i++) {
            if (nft.ownerOf(idNFT[i]) != msg.sender) {
                revert ForceNFTControlSenderNotOwnerNFT(_level, idNFT[i]);
            }
            burnNFT(_level, idNFT[i]);
        }
        return giveNFT(msg.sender, _level + 1);
    }

    function setFactorForEnergyTokens(string memory _name, uint256 _factor) external override onlyOwner {
        if (!registry.checkName(_name)) {
            revert ForceNFTControlThisNameIsEmpty();
        }
        getFactorForEnergyTokens[registry.metaProjectId(_name)] = _factor;
    }

    function setPriceUpToFirstLevel(uint256 _price) external override onlyOwner {
        getPriceUpToFirstLevel = _price;
    }

    function setPriceFirstEmptyNFT(uint256 _price) external override onlyOwner {
        getPriceFirstEmptyNFT = _price;
    }

    function setAmontNFTForMerge(uint256 amount) external override onlyOwner {
        getAmontNFTForMerge = amount;
    }

    function setRequeredLevels(string memory _name, uint256 _requeredLevel) external override onlyOwner {
        if (!registry.checkName(_name)) {
            revert ForceNFTControlThisNameIsEmpty();
        }
        requeredLevels[registry.metaProjectId(_name)] = _requeredLevel;
    }

    function setShareForLevelFromPool(uint256[] memory _shares) external onlyOwner {
        if (_shares.length != registry.getMaxLvlNFT() + 1) {
            revert ForceNFTControlNotEnoughValuesInArray(registry.getMaxLvlNFT() + 1);
        }
        uint256 sum;
        for (uint256 i = 0; i < _shares.length; i++) {
            sum += _shares[i];
            getShareForLevelFromPool[i] = _shares[i];
        }
        if (sum != SCALE) {
            revert ForceNFTControlNotHundredPercent();
        }
    }

    function distributionPool() external override onlyOwner returns (uint256) {
        return distributionPool(IERC20(registry.getForceRewardCoin()).balanceOf(registry.getForcePool()));
    }

    function claimReward(
        uint256 _idDistribution,
        uint256[] memory _level,
        uint256[] memory idsNFTs
    ) external override {
        uint256 reward;
        if (_idDistribution >= indexNextDistribution) {
            revert ForceNFTControlThereWasNoDistribution();
        }
        if (_level.length != idsNFTs.length) {
            revert ForceNFTControlNotEqualLengthArrays();
        }
        for (uint256 i = 0; i < idsNFTs.length; i++) {
            IForceNFT nft = IForceNFT(registry.getForceNFT(_level[i]));
            if (distributions[_idDistribution][_level[i]].countNFT == 0) {
                revert ForceNFTNoRewardsForThisLevel(_level[i]);
            }
            if (idsNFTs[i] > distributions[_idDistribution][_level[i]].countNFT - 1) {
                revert ForceNFTControlNFTCreatedAfterDistribution(_level[i], idsNFTs[i]);
            }
            if (nft.ownerOf(idsNFTs[i]) != msg.sender) {
                revert ForceNFTControlSenderNotOwnerNFT(_level[i], idsNFTs[i]);
            }
            if (nftRewarded[_idDistribution][_level[i]][idsNFTs[i]]) {
                revert ForceNFTControlNFTRewarded(_level[i], idsNFTs[i]);
            }
            nftRewarded[_idDistribution][_level[i]][idsNFTs[i]] = true;
            reward += distributions[_idDistribution][_level[i]].oneShareStableCoin;
        }
        IERC20(registry.getForceRewardCoin()).transferFrom(registry.getForcePool(), msg.sender, reward);
    }

    function distributionPool(uint256 amount) public override onlyOwner returns (uint256) {
        if (amount > IERC20(registry.getForceRewardCoin()).balanceOf(registry.getForcePool())) {
            revert ForceNFTDistributionAmountMoreThanBalance();
        }
        for (uint256 i = 0; i <= registry.getMaxLvlNFT(); i++) {
            distributions[indexNextDistribution][i].oneShareStableCoin =
                amount.mul(getShareForLevelFromPool[i]) /
                IForceNFT(registry.getForceNFT(i)).totalSupply();
            distributions[indexNextDistribution][i].countNFT = nftIndexes[i];
        }
        indexNextDistribution++;
        return indexNextDistribution - 1;
    }

    function giveNFT(address _user, uint256 _level) internal returns (uint256) {
        if (_level > registry.getMaxLvlNFT()) {
            revert ForceNFTControlThisLevelNFTMoreMax();
        }
        IForceNFT nft = IForceNFT(registry.getForceNFT(_level));
        nft.mint(_user, nftIndexes[_level]);
        nftIndexes[_level]++;
        return nftIndexes[_level] - 1;
    }

    function burnNFT(uint256 _level, uint256 id) internal {
        if (_level > registry.getMaxLvlNFT()) {
            revert ForceNFTControlThisLevelNFTMoreMax();
        }
        IForceNFT nft = IForceNFT(registry.getForceNFT(_level));
        nft.burn(id);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

struct Distribution {
    uint256 oneShareStableCoin;
    uint256 countNFT;
}

interface IControl {
    function getEmptyNFT(uint256[] memory amounts) external returns (uint256);

    function levelUpEmptyNFT(uint256 id, uint256[] memory amountsEnergyCoin) external returns (uint256[] memory);

    function mergeNFT(uint256 _level, uint256[] memory idNFT) external returns (uint256);

    function setFactorForEnergyTokens(string memory _name, uint256 _factor) external;

    function setPriceUpToFirstLevel(uint256 price) external;

    function setPriceFirstEmptyNFT(uint256 _price) external;

    function setAmontNFTForMerge(uint256 amount) external;

    function setRequeredLevels(string memory _name, uint256 _requeredLevel) external;

    function distributionPool() external returns (uint256);

    function distributionPool(uint256 amount) external returns (uint256);

    function claimReward(
        uint256 _idDistribution,
        uint256[] memory _level,
        uint256[] memory idsNFTs
    ) external;

    function getFactorForEnergyTokens(uint256 id) external view returns (uint256);

    function getPriceUpToFirstLevel() external view returns (uint256);

    function getPriceFirstEmptyNFT() external view returns (uint256);

    function getAmontNFTForMerge() external view returns (uint256);

    function getShareForLevelFromPool(uint256 level) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEnergyCoin is IERC20 {
    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IForceNFT is IERC721Enumerable {
    function mint(address account, uint256 id) external;

    function burn(uint256 id) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IMetaProject {
    function getLevelForNFT(address _user) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IRegistry {
    function setForceNFT(uint256 level, address _forceNFT) external;

    function setForcePool(address _forcePool) external;

    function setForceRewardCoin(address _forceCoin) external;

    function setMetaProject(
        string calldata name,
        address metaProject,
        address energyCoin
    ) external;

    function setControlContract(address _control) external;

    function deleteMetaProject(string memory _name) external;

    function deleteMetaProject(uint256 id) external;

    function setMaxLevelNFT(uint256 lvl) external;

    function getForceNFT(uint256 level) external view returns (address);

    function getControlContract() external view returns (address);

    function getForcePool() external view returns (address);

    function getForceRewardCoin() external view returns (address);

    function getMetaProject(string calldata _nameMetaProject) external view returns (address);

    function getMetaProject(uint256) external view returns (address);

    function getEnergyToken(string calldata _nameMetaProject) external view returns (address);

    function getEnergyToken(uint256 id) external view returns (address);

    function metaProjectId(string calldata name) external view returns (uint256);

    function metaProjectName(uint256 id) external view returns (string memory);

    function getAmountMetaProject() external view returns (uint256);

    function getIndexProject(uint256 num) external view returns (uint256);

    function getAllIndexes() external view returns (uint256[] memory);

    function checkName(string memory _name) external view returns (bool);

    function getNameProject(uint256 id) external view returns (string memory name);

    function getMaxLvlNFT() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

uint256 constant SCALE = 1e18;
uint256 constant HALF_SCALE = 5e17;
/// @dev Largest power of two divisor of scale.
uint256 constant SCALE_LPOTD = 262144;

/// @dev Scale inverted mod 2**256.

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }

    function convertIntToFixPoint(uint256 integer) internal pure returns (uint256 result) {
        result = integer * SCALE;
    }

    function convertFixPointToInt(uint256 integer) internal pure returns (uint256 result) {
        result = integer / SCALE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Math {
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}