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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Interface/IERC1155.sol';

/**
 * @title ERC1155Converter
 * @dev A contract that allows users to swap an ERC1155 token for another ERC1155 token.
 */
contract ERC1155Converter is Ownable {
  address public token;
  IERC1155 public erc1155Contract;
  uint256 public minimumTokenBalanceToBurn = 9000;
  uint256 public wigNftToMint = 1;
  bytes32 public merkleProof;
  uint256 public quantityLimitPerWallet;
  uint256 public pricePerToken;
  address public currency;
  uint256 public hairTokenId;
  uint256 public wigTokenId;

  event TokenUpdated(address _token);
  event QuantityPerWalletUpdated(uint256 _quantityLimitPerWallet);
  event PricePerTokenUpdated(uint256 _pricePerToken);
  event PurchaseCurrencyUpdated(address _currency);
  event HairTokenIdUpdated(uint256 _hairTokenId);
  event WigTokenIdUpdated(uint256 _wigTokenId);
  event MinimumTokenBalanceToBurnUpdated(uint256 _minimumTokenBalanceToBurn);
  event WigNFTMintedSuccessfully(
    address _address,
    address _currency,
    uint256 _wigTokenId,
    uint256 _pricePerToken
  );
  event WigNftToMintUpdated(uint256 _wigNftToMint);

  /**
   * @dev Initializes the contract with the specified parameters.
   * @param _token The address of the ERC1155 token being used for swapping NFT Tokens.
   * @param _merkleProof The merkle proof used for verification during token minting.
   * @param _quantityLimitPerWallet The maximum quantity of the new token that can be minted per wallet.
   * @param _pricePerToken The price per token for the new ERC1155 token.
   * @param _currency The address of the currency used for the purchase.
   * @param _hairTokenId The token ID of the ERC1155 token being burned.
   * @param _wigTokenId The token ID of the new ERC1155 token (Wig NFT).
   */
  constructor(
    address _token,
    bytes32 _merkleProof,
    uint256 _quantityLimitPerWallet,
    uint256 _pricePerToken,
    address _currency,
    uint256 _hairTokenId,
    uint256 _wigTokenId
  ) {
    token = _token;
    erc1155Contract = IERC1155(_token);
    merkleProof = _merkleProof;
    quantityLimitPerWallet = _quantityLimitPerWallet;
    pricePerToken = _pricePerToken;
    currency = _currency;
    hairTokenId = _hairTokenId;
    wigTokenId = _wigTokenId;
  }

  /**
   * @dev Performs the token swap for the caller.
   * The caller must have a token balance greater than or equal to minimumTokenBalanceToBurn.
   * The function burns the specified amount of the old token and mints the specified quantity of the new token for the caller.
   */

  function swapTokens() external {
    require(
      minimumTokenBalanceToBurn <= erc1155Contract.balanceOf(msg.sender, 0),
      "Address Doesn't have reuired balance"
    );
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes32[] memory proof = new bytes32[](1);
    AllowlistProof[] memory allowlistProof = new AllowlistProof[](1);
    proof[0] = merkleProof;
    allowlistProof[0].proof = proof;
    allowlistProof[0].quantityLimitPerWallet = quantityLimitPerWallet;
    allowlistProof[0].pricePerToken = pricePerToken;
    allowlistProof[0].currency = currency;
    ids[0] = hairTokenId;
    amounts[0] = minimumTokenBalanceToBurn;
    erc1155Contract.burnBatch(msg.sender, ids, amounts);
    erc1155Contract.claim(
      msg.sender,
      wigTokenId,
      wigNftToMint,
      currency,
      pricePerToken,
      allowlistProof[0],
      '0x'
    );
    emit WigNFTMintedSuccessfully(
      msg.sender,
      currency,
      wigTokenId,
      pricePerToken
    );
  }

  /**
   * @dev Updates the address of the ERC1155 token being used for swapping NFT Tokens.
   * Only the contract owner can call this function.
   * @param _token The address of the new ERC1155 token.
   */

  function updateToken(address _token) external onlyOwner {
    token = _token;
    emit TokenUpdated(_token);
  }

  /**
   * @dev Updates the merkle proof used for verification during token minting.
   * Only the contract owner can call this function.
   * @param _merkleProof The new merkle proof.
   */
  function updateMerkleProof(bytes32 _merkleProof) external onlyOwner {
    merkleProof = _merkleProof;
  }

  /**
   * @dev Updates the maximum quantity of the new token that can be minted per wallet.
   * Only the contract owner can call this function.
   * @param _quantityLimitPerWallet The new quantity limit per wallet.
   */
  function updateQuantityPerWallet(
    uint256 _quantityLimitPerWallet
  ) external onlyOwner {
    quantityLimitPerWallet = _quantityLimitPerWallet;
    emit QuantityPerWalletUpdated(_quantityLimitPerWallet);
  }

  /**
   * @dev Updates the price per token for the new ERC1155 token.
   * Only the contract owner can call this function.
   * @param _pricePerToken The new price per token.
   */
  function updatePricePerToken(uint256 _pricePerToken) external onlyOwner {
    pricePerToken = _pricePerToken;
    emit PricePerTokenUpdated(_pricePerToken);
  }

  /**
   * @dev Updates the address of the currency used for the purchase.
   * Only the contract owner can call this function.
   * @param _currency The address of the new currency.
   */
  function updatePurchaseCurrency(address _currency) external onlyOwner {
    currency = _currency;
    emit PurchaseCurrencyUpdated(_currency);
  }

  /**
   * @dev Updates the token ID of the ERC1155 token being burned.
   * Only the contract owner can call this function.
   * @param _hairTokenId The new token ID of the ERC1155 token being burned.
   */
  function updateHairTokenId(uint256 _hairTokenId) external onlyOwner {
    hairTokenId = _hairTokenId;
    emit HairTokenIdUpdated(_hairTokenId);
  }

  /**
   * @dev Updates the token ID of the new ERC1155 token (Wig NFT).
   * Only the contract owner can call this function.
   * @param _wigTokenId The new token ID of the new ERC1155 token (Wig NFT).
   */
  function updateWigTokenId(uint256 _wigTokenId) external onlyOwner {
    wigTokenId = _wigTokenId;
    emit WigTokenIdUpdated(_wigTokenId);
  }

  /**
   * @dev Updates the minimum token balance required to burn for the token swap.
   * Only the contract owner can call this function.
   * @param _minimumTokenBalanceToBurn The new minimum token balance required to burn.
   */
  function updateMinimumTokenBalanceToBurn(
    uint256 _minimumTokenBalanceToBurn
  ) external onlyOwner {
    minimumTokenBalanceToBurn = _minimumTokenBalanceToBurn;
    emit MinimumTokenBalanceToBurnUpdated(_minimumTokenBalanceToBurn);
  }

  /**
   * @dev Updates the quantity of the new ERC1155 token (Wig NFT) to mint per swap.
   * Only the contract owner can call this function.
   * @param _wigNftToMint The new quantity of the new ERC1155 token (Wig NFT) to mint per swap.
   */
  function updateWigNFTToMint(uint256 _wigNftToMint) external onlyOwner {
    wigNftToMint = _wigNftToMint;
    emit WigNftToMintUpdated(_wigNftToMint);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
struct AllowlistProof {
  bytes32[] proof;
  uint256 quantityLimitPerWallet;
  uint256 pricePerToken;
  address currency;
}

interface IERC1155 {
  function balanceOf(
    address account,
    uint256 id
  ) external view returns (uint256);

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) external;

  function claim(
    address _receiver,
    uint256 _tokenId,
    uint256 _quantity,
    address _currency,
    uint256 _pricePerToken,
    AllowlistProof calldata _allowlistProof,
    bytes memory _data
  ) external;
}