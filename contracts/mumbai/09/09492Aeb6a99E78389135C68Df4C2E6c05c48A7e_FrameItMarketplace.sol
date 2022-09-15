// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../metatx/FrameItContext.sol";
import "../nfts/IFrameItLootBox.sol";
import "../oracle/IUniswapV3Twap.sol";
import "../utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FrameItMarketplace is FrameItContext {
    using SafeERC20 for IERC20;

    struct PrimarySaleStruct {
        uint256 _price;
        address _nft;
        uint24 _numberOfNFTs;
        address _token;
        uint24 _sold;
        address _owner;
        uint64 _startDate;
        uint64 _endDate;
        uint24 _maxAllowedSale;
    }

    struct SecondarySaleStruct {
        address _owner;
        address _nft;
        address _token;
        uint256 _id;
        uint256 _price;
        uint256 _expirationDate;
    }

    struct OfferStruct {
        bool _accepted;
        bool _cancelled;
    }

    address private rungieOracle;
    address private rungieToken;
    uint256 public primarySaleIDNonceCounter;
    uint256 public secondarySaleIDNonceCounter;
    mapping(uint256 => PrimarySaleStruct) private primarySales;
    mapping(uint256 => SecondarySaleStruct) private secondarySales;
    mapping(bytes32 => OfferStruct) private offers;

    event PrimarySaleLootBoxEvent(address indexed _owner, address indexed _nftAddress, uint24 _numberOfNFTs, uint256 _price, address _token, uint256 _saleID, uint64 _startDate, uint64 _endDate);
    event CancelPrimarySaleLootBoxEvent(uint256 _saleID);
    event BuyLootBoxEvent(address indexed _seller, address indexed _buyer, uint256 _saleID, uint256 _amount, uint256 _price, address _token, uint256[] _ids);

    event SecondarySaleLootBoxEvent(address indexed _owner, address indexed _nftAddress, uint256 _id, uint256 _price, address _token, uint256 _expirationDate, uint256 _saleID);
    event CancelSecondarySaleLootBoxEvent(uint256 _saleID);
    event BuySecondaryEvent(address indexed _seller, address indexed _buyer, address indexed _nftAddress, uint256 _id, uint256 _price, address _token);

    event OfferAccepted(bytes32 _offerHash);
    event OfferCancelled(bytes32 _offerHash);

    constructor(address _forwarder, address _rungieOracle, address _rungieToken, uint256 _primarySaleIDNonceCounter, uint256 _secondarySaleIDNonceCounter) FrameItContext(_forwarder) {
        primarySaleIDNonceCounter = _primarySaleIDNonceCounter;
        secondarySaleIDNonceCounter = _secondarySaleIDNonceCounter;
        rungieOracle = _rungieOracle;
        rungieToken = _rungieToken;
    }

    function setPrimarySaleFullLootBox(address _nftAddress, uint24 _numberOfNFTs, uint256 _price, address _token, uint64 _startDate, uint64 _endDate, uint16 _maxAllowedSale) external {
        require(IFrameItLootBox(_nftAddress).owner() == _msgSender(), "OnlyOwner");
        require(_endDate > _startDate, "BadDates");

        PrimarySaleStruct memory sale = PrimarySaleStruct({
            _price: _price,
            _nft: _nftAddress,
            _numberOfNFTs: _numberOfNFTs,
            _token: _token,
            _sold: 0,
            _owner: _msgSender(),
            _startDate: _startDate,
            _endDate: _endDate,
            _maxAllowedSale: _maxAllowedSale
        });

        primarySaleIDNonceCounter++;
        primarySales[primarySaleIDNonceCounter] = sale;

        emit PrimarySaleLootBoxEvent(_msgSender(), _nftAddress, _numberOfNFTs, _price, _token, primarySaleIDNonceCounter, _startDate, _endDate);
    }

    function cancelPrimarySaleLootBox(uint256 _saleID) external {
        PrimarySaleStruct memory sale = primarySales[_saleID];
        require(sale._owner == _msgSender(), "BadSaleOwner");

        delete primarySales[_saleID];

        emit CancelPrimarySaleLootBoxEvent(_saleID);
    }

    function getPrimarySaleLootBoxData(uint256 _saleID) external view returns(address _owner, address _nftAddress, uint24 _numberOfNFTs, uint24 _sold, uint256 _price, address _token, uint64 _startDate, uint64 _endDate) {
        PrimarySaleStruct memory sale = primarySales[_saleID];
        return (sale._owner, sale._nft, sale._numberOfNFTs, sale._sold, sale._price, sale._token, sale._startDate, sale._endDate);
    }

    // TODO. Limitar que solo se pueda comprar 5 sobres al minuto
    function buyPrimarySaleLootBox(uint256 _saleID, uint24 _amount, bool _payInRungies) external payable {
        PrimarySaleStruct storage sale = primarySales[_saleID];
        require(_amount <= sale._maxAllowedSale, "MaxAllowed");
        require(block.timestamp >= sale._startDate, "SaleNotStarted");
        if (sale._endDate > 0) require(block.timestamp <= sale._endDate, "SaleEnded");
        if (sale._token == address(0)) require(msg.value == (sale._price * _amount), "BadAmount");
        require(sale._sold + _amount <= sale._numberOfNFTs, "NotEnoughNFTs");

        uint256[] memory _ids = new uint256[](_amount);
        uint256 _id = sale._sold;
        for (uint256 i=0; i<_amount; i++) {
            _id++;
            require(IERC721(sale._nft).ownerOf(_id) == sale._nft, "NFTIdNotFound");
            IERC721(sale._nft).safeTransferFrom(sale._nft, _msgSender(), _id);
            _ids[i] = _id;
        }
        sale._sold += _amount;

        address salesWallet = IFrameItLootBox(sale._nft).salesWallet();

        if (_payInRungies == false) {
            if (sale._token == address(0)) {
                (bool success, ) = salesWallet.call{value: msg.value}("");
                require(success == true, "BadTransfer");
            }
            else IERC20(sale._token).safeTransferFrom(_msgSender(), salesWallet, sale._price);
        } else {
            // TODO. Test pay with Rungies?? Why the owner is going to accept 10% less than expected???
            uint256 priceInRungies = _calculateRungiesPrice(sale._price * _amount, sale._token) * 9 / 10;
            IERC20(rungieToken).safeTransferFrom(_msgSender(), salesWallet, priceInRungies);
        }

        emit BuyLootBoxEvent(sale._owner, _msgSender(), _saleID, _amount, msg.value, sale._token, _ids);
    }

    function setSecondarySale(address _nftAddress, uint256 _id, uint256 _price, address _token, uint256 _expirationDate) external {
        require(IERC721(_nftAddress).ownerOf(_id) == _msgSender(), "BadOwner");
        if (_expirationDate > 0 ) require(block.timestamp < _expirationDate, "BadDate");

        SecondarySaleStruct memory sale = SecondarySaleStruct({
            _owner: _msgSender(),
            _nft: _nftAddress,
            _id: _id,
            _price: _price,
            _token: _token,
            _expirationDate: _expirationDate
        });

        secondarySaleIDNonceCounter++;
        secondarySales[secondarySaleIDNonceCounter] = sale;

        emit SecondarySaleLootBoxEvent(_msgSender(), _nftAddress, _id, _price, _token, _expirationDate, secondarySaleIDNonceCounter);
    }

    function cancelSecondarySaleLootBox(uint256 _saleID) external {
        SecondarySaleStruct memory sale = secondarySales[_saleID];
        require(sale._owner == _msgSender(), "BadSaleOwner");

        delete secondarySales[_saleID];

        emit CancelSecondarySaleLootBoxEvent(_saleID);
    }

    function getSecondarySaleData(uint256 _saleID) external view returns(address _owner, address _nftAddress, uint256 _id, uint256 _price, address _token, uint256 _expirationDate) {
        SecondarySaleStruct memory sale = secondarySales[_saleID];
        return (sale._owner, sale._nft, sale._id, sale._price, sale._token, sale._expirationDate);
    }

    function buySecondarySale(uint256[] calldata _saleIDs) external payable {
        uint256 totalPrice = 0;

        for (uint256 i=0; i<_saleIDs.length; i++) {
            uint256 saleID = _saleIDs[i];
            SecondarySaleStruct memory sale = secondarySales[saleID];
            if (sale._token == address(0)) totalPrice += sale._price;
            require(IERC721(sale._nft).ownerOf(sale._id) == sale._owner, "BadNFTOwner");
            if (sale._expirationDate > 0) require(block.timestamp <= sale._expirationDate, "SaleEnded");
            
            delete secondarySales[saleID];

            address salesWallet = IFrameItNFTCommons(sale._nft).salesWallet();

            if (sale._token == address(0)) {
                (bool success, ) = salesWallet.call{value: sale._price}("");
                require(success == true, "BadTransfer");
            }
            else IERC20(sale._token).safeTransferFrom(_msgSender(), salesWallet, sale._price);
            
            IERC721(sale._nft).safeTransferFrom(sale._owner, _msgSender(), sale._id);

            emit BuySecondaryEvent(sale._owner, _msgSender(), sale._nft, sale._id, sale._price, sale._token);
        }

        require(msg.value == totalPrice, "BadAmount");
    }

    function claimOffer(bytes calldata _message, bytes memory _messageLen, bytes calldata _signature) external payable {
        // NFT owner signature
        address signatureOwner = _decodeSignature(_message, _messageLen, _signature);
        // Decode owner message accepting the offer
        (address _signer, bytes memory _signatureMessage, bytes memory _signatureMessageLen, bytes memory _signatureSignature, uint64 _signatureExpirationDate) = abi.decode(_message,(address, bytes, bytes, bytes, uint64));
        require(signatureOwner == _signer, "OriginalBadSigner");
        // Check offer expired date
        if (_signatureExpirationDate > 0) require(block.timestamp <= _signatureExpirationDate, "OfferExpired");
        // Get offerer signature
        address offerer = _decodeSignature(_signatureMessage, _signatureMessageLen, _signatureSignature);
        // Decode the offer data
        (address _offerer, address _nft, uint64 _id, uint256 _price, address _token, uint64 _expirationDate) = abi.decode(_signatureMessage,(address, address, uint64, uint256, address, uint64));
        // Calculate the hash of the offer
        bytes32 signatureHash = keccak256(_signatureSignature);
        // Check the offer is still valid
        require(offers[signatureHash]._cancelled == false && offers[signatureHash]._accepted == false, "OfferNoValid");
        // Check the offerer is the same in the messages
        require(_offerer == offerer, "BadSigner");
        // Check the paid amount
        if (_token == address(0)) require(msg.value == _price, "BadAmount");
        // Check the owner is the one that signed the first message
        require(IERC721(_nft).ownerOf(_id) == signatureOwner, "BadNFTOwner");
        // Check original expiration date
        if (_expirationDate > 0) require(block.timestamp <= _expirationDate, "OriginalOfferExpired");

        offers[signatureHash]._accepted = true;

        address salesWallet = IFrameItNFTCommons(_nft).salesWallet();

        if (_token == address(0)) {
            (bool success, ) = salesWallet.call{value: msg.value}("");
            require(success == true, "BadTransfer");
        }
        else IERC20(_token).safeTransferFrom(_msgSender(), salesWallet, _price);
        
        IERC721(_nft).safeTransferFrom(_signer, _offerer, _id);

        emit OfferAccepted(signatureHash);
    }

    function cancelOffer(bytes calldata _signature) external payable {
        bytes32 signatureHash = keccak256(_signature);
        offers[signatureHash]._cancelled = true;

        emit OfferCancelled(signatureHash);
    }

    function _calculateRungiesPrice(uint256 _amount, address _token) internal view returns(uint256) {
        return IUniswapV3Twap(rungieOracle).estimateAmountOut(_token, uint128(_amount), 30);
    }

    /**
     * @notice Decode the signature of a message
     * @param _message        --> Encoded message
     * @param _messageLength  --> Message length
     * @param _signature      --> User signature
     * @return Returns the message signer
     */
    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(msg.sender, newOwner);
    }

    function claimOwnership() external {
        require(msg.sender == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IUniswapV3Twap {

    function estimateAmountOut(address _tokenIn, uint128 _amountIn, uint32 _secondsAgo) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItNFTCommons {

    function salesWallet() external view returns(address);
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IFrameItNFTCommons.sol";

interface IFrameItLootBox is IFrameItNFTCommons {

    function initialize(string memory _newname, string memory _newsymbol, address _nftContract, address _owner, string memory _newuri, uint256 _minimumTimeToOpen, address _factory) external;
    function setSalesWallet(uint256 _royaltiesFeeInBips, address _salesWallet) external;
    function mintLootBoxes(bytes32[] calldata _signatures, address _signer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract FrameItContext is ERC2771Context {

    constructor (address _forwarder) ERC2771Context(_forwarder) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}