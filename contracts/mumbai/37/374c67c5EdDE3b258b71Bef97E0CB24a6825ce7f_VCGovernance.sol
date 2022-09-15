// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IMarketplaceFixedPrice.sol";
import "../interfaces/IMarketplaceAuction.sol";
import "../interfaces/IArtistNft.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();

    event ProtocolComponentsSet(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketplaceFixedPrice,
        address marketplaceAuction,
        address artistNft,
        address pocNft
    );

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    IMarketplaceFixedPrice public marketplaceFixedPrice;
    IMarketplaceAuction public marketplaceAuction;
    IArtistNft public artistNft;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function protocolComponents(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _marketplaceFixedPrice,
        address _marketplaceAuction,
        address _artistNft,
        address _pocNft
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        marketplaceFixedPrice = IMarketplaceFixedPrice(_marketplaceFixedPrice);
        marketplaceAuction = IMarketplaceAuction(_marketplaceAuction);
        artistNft = IArtistNft(_artistNft);
        pocNft = IPoCNft(_pocNft);

        _setPoCNft(_pocNft);
        _setMinterRoleArtistNft(_marketplaceFixedPrice);
        _setMinterRoleArtistNft(_marketplaceAuction);
        _setCurrency(_currency);

        emit ProtocolComponentsSet(
            _vcPool,
            _vcStarter,
            _currency,
            _marketplaceFixedPrice,
            _marketplaceAuction,
            _artistNft,
            _pocNft
        );
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceFixedPriceWithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceFixedPrice.withdrawTo(_token, _to, _amount);
    }

    function marketplaceAuctionWithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceAuction.withdrawTo(_token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketplaceFixedPrice.setPoCNft(_pocNft);
        marketplaceAuction.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    function whitelistTokens(address[] memory _tokens) external {
        _onlyAdmin();
        marketplaceFixedPrice.whitelistTokens(_tokens);
        marketplaceAuction.whitelistTokens(_tokens);
    }

    function blacklistTokens(address[] memory _tokens) external {
        _onlyAdmin();
        marketplaceFixedPrice.blacklistTokens(_tokens);
        marketplaceAuction.blacklistTokens(_tokens);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        marketplaceAuction.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMinTotalFeeBps(_minTotalFeeBps);
        marketplaceAuction.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFee(uint256 _marketplaceFee) external {
        _onlyAdmin();
        marketplaceFixedPrice.setMarketplaceFee(_marketplaceFee);
        marketplaceAuction.setMarketplaceFee(_marketplaceFee);
    }

    /////////////////////////////////////////
    // ARTIST NFT SETUP THROUGH GOVERNANCE //
    /////////////////////////////////////////

    function setMinterRoleArtistNft(address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtistNft(_minter);
    }

    function _setMinterRoleArtistNft(address _marketplace) private {
        artistNft.grantMinterRole(_marketplace);
    }

    function setRoyaltyInfoArtistNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artistNft.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artistNft.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artistNft.setMaxBatchSize(_maxBatchSize);
    }

    function grantCreatorRoleArtistNft(address _newCreator) external {
        _onlyAdmin();
        artistNft.addCreator(_newCreator);
    }

    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    function setMarketplaceFixedPriceStarter(address _newMarketplaceFixedPrice) external {
        _onlyAdmin();
        starter.setMarketplaceFixedPrice(_newMarketplaceFixedPrice);
    }

    function setMarketplaceAuctionStarter(address _newMarketplaceAuction) external {
        _onlyAdmin();
        starter.setMarketplaceAuction(_newMarketplaceAuction);
    }

    // NECESITAMOS UN BLACKLIST O UN REMOVE WHITELIST??
    function whitelistLabsStarter(address[] memory _labs) external {
        _onlyAdmin();
        starter.whitelistLabs(_labs);
    }

    function setQuorumPollStarter(uint256 _quorumPoll) external {
        _onlyAdmin();
        if (_quorumPoll > 100) {
            revert GovInvalidQuorumPoll();
        }
        starter.setQuorumPoll(_quorumPoll);
    }

    function setMaxPollDurationStarter(uint256 _maxPollDuration) external {
        // should we check something here??
        _onlyAdmin();
        starter.setMaxPollDuration(_maxPollDuration);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _setCurrency(_currency);
    }

    function _setCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.setCurrency(_currency);
        pool.setCurrency(_currency);
        marketplaceAuction.setCurrency(_currency);
        marketplaceFixedPrice.setCurrency(_currency);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    function currency() external returns (IERC20);

    function setPoCNft(address _poCNFT) external;

    function setMarketplaceAuction(address _newMarketplace) external;

    function setMarketplaceFixedPrice(address _newMarketplace) external;

    function whitelistLabs(address[] memory _labs) external;

    function setCurrency(IERC20 _currency) external;

    function setQuorumPoll(uint256 _quorumPoll) external;

    function setMaxPollDuration(uint256 _maxPollDuration) external;

    function maxPollDuration() external view returns (uint256);

    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarketplaceFixedPrice {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external returns (uint256 _currentTokenId);

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarketplaceAuction {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IArtistNft is IERC1155 {
    function mint(uint256 _tokenId, uint256 _amount) external;

    function exists(uint256 _tokenId) external returns (bool);

    function totalSupply(uint256 _tokenId) external returns (uint256);

    function lazyTotalSupply(uint256 _tokenId) external returns (uint256);

    function requireCanRequestMint(
        address _by,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function grantRole(address _newCreator) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function addCreator(address _creator) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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