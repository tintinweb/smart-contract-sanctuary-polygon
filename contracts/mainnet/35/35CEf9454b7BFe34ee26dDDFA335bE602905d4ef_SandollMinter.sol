//SPDX-License-Identifier: Unlicense
//Company: Sandll-Metalab
//Writer: Super Moon
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Minter.sol";
import "./Data.sol";
import "./Controlable.sol";

contract SandollMinter is Controlable, IERC721Receiver {

    event Reclaimed(address indexed from, address indexed to, uint256 idx);
    event Decombined(address indexed from, address indexed to, uint256 idx);

    using Address for address;
    using Counters for Counters.Counter;
    
    address private _fonter;
    Counters.Counter private _tokenIds;
    mapping (uint256 => FontOwner) private _fontOwner;
    mapping (address => Font[]) private _fonts;

    constructor() {}

    modifier onlyFonter() {
        require(_msgSender() == _fonter, "You are not fonter.");
        _;
    }

    function getTokenURI(uint256 tokenId) external view returns (Font memory) {
        require(_fonter != address(0), "Fonter should not be null.");
        require(tokenId > 0, "TokenId should be bigger than zero.");
        FontOwner memory fontOwner = _fontOwner[tokenId];
        require(fontOwner.owner != address(0), "Address is null.");
        return fontOwner.font;
    }

    function getTokenURIs(address tokenOwner) external view returns (Font[] memory) {
        return _fonts[tokenOwner];
    }

    function setFonter(address fonter) external onlyControllers {
        _fonter = fonter;
    }

    function getFonter() external view onlyControllers returns (address) {
        return _fonter;
    }

    function removeFonter() external onlyControllers {
        _fonter = address(0);
    }

    function setMintPrice(uint256 price) external onlyControllers {
        require(_fonter.isContract(), "Fonter is not contract.");
        MintController(_fonter).setMintPrice(price);
    }

    function setMinter(address minter) external onlyControllers {
        require(_fonter.isContract(), "Fonter is not contract.");
        require(_fonter != address(0), "Fonter is null.");
        Minter(_fonter).transferMinter(minter);
    }

    function removeMinter() external onlyControllers {
        require(_fonter.isContract(), "Fonter is not contract.");
        require(_fonter != address(0), "Fonter is null.");
        Minter(_fonter).renounceMinter();
    }

    function clearMintInfo(address recipient, uint256 tokenId) external onlyControllers {
        require(tokenId > 0, "TokenId should be grater than 0.");
        FontOwner memory fontOwner = _fontOwner[tokenId];
        Font memory font = fontOwner.font;
        if(fontOwner.owner != recipient) { return; }
        bytes32 blank = keccak256(abi.encodePacked(""));
        if((keccak256(abi.encodePacked(font.tokenURI)) != blank) || 
        (keccak256(abi.encodePacked(font.image)) != blank)) { return; }
        remove(fontOwner.owner, tokenId);
    }

    function reserveMint(address recipient, bool combined, uint256 idx) public onlyFonter returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        uint16 ftype = 0;
        if(combined) { ftype = 2; }
        _fontOwner[tokenId] = FontOwner(recipient, Font(tokenId, ftype, 0, idx, 0, "", "", "", "", new uint256[](0)));
        _fonts[recipient].push(_fontOwner[tokenId].font);
        return tokenId;
    }

    function decombine(address recipient, uint256 tokenId) public onlyFonter {    
        FontOwner memory fontOwner = _fontOwner[tokenId];
        require(recipient == fontOwner.owner, "Font owner is different.");
        address contractAddress = address(this);
        Font memory font = fontOwner.font;
        for(uint i = 0; i < font.reclaims.length; i++) {
            IERC721(_fonter).safeTransferFrom(contractAddress, fontOwner.owner, font.reclaims[i]);
            emit Decombined(contractAddress, fontOwner.owner, font.reclaims[i]);
        }
        remove(fontOwner.owner, tokenId);
        delete _fontOwner[tokenId].font;
    }

    function mint(uint256 tokenId, uint16 ftype, uint16 edition, uint16 idx, uint256 shift, string memory name, 
    string memory sub, string memory image, string memory tokenURI, uint256[] memory reclaims) external onlyControllers {

        FontOwner memory fontOwner = _fontOwner[tokenId];
        require(fontOwner.owner != address(0), "Address is null.");
        Font[] memory fonts = _fonts[fontOwner.owner];
        address contractAddress = address(this);
        bool minted = false;
        for (uint i = 0; i < fonts.length; i++) {
            if(fonts[i].tokenId != tokenId) { continue; }
            _fonts[fontOwner.owner][i].ftype = ftype;
            _fonts[fontOwner.owner][i].edition = edition;
            _fonts[fontOwner.owner][i].idx = idx;
            _fonts[fontOwner.owner][i].shift = shift;
            _fonts[fontOwner.owner][i].name = name;
            _fonts[fontOwner.owner][i].sub = sub;
            _fonts[fontOwner.owner][i].image = image;
            _fonts[fontOwner.owner][i].tokenURI = tokenURI;
            _fonts[fontOwner.owner][i].reclaims = reclaims;
            _fontOwner[fonts[i].tokenId].font = _fonts[fontOwner.owner][i];
            MintController(_fonter).mint(fontOwner.owner, fonts[i].tokenId, tokenURI);
            minted = true;
            break;
        }

        for(uint j = 0; j < reclaims.length; j++) {
            IERC721(_fonter).safeTransferFrom(fontOwner.owner, contractAddress, reclaims[j]);
            emit Reclaimed(fontOwner.owner, contractAddress, reclaims[j]);
        }
        require(minted, "Mint item should not be empty.");
    }

    function move(address from, address to, uint256 tokenId) public onlyFonter {
        Font[] storage fonts = _fonts[from];
        for(uint i = 0; i < fonts.length; i++) {
            if(fonts[i].tokenId != tokenId) { continue; }
            Font storage font = fonts[i];
            Font memory newFont = Font(font.tokenId, font.ftype, font.edition, font.idx, font.shift, 
                font.name, font.sub, font.image, font.tokenURI, font.reclaims);
            _fonts[to].push(newFont);
            delete _fontOwner[tokenId];
            _fontOwner[tokenId] = FontOwner(to, newFont);
            _fonts[from][i] = _fonts[from][fonts.length - 1];
            _fonts[from].pop();
            break;
        }
    }

    function remove(address from, uint256 tokenId) internal {
        Font[] storage fonts = _fonts[from];
        for(uint i = 0; i < fonts.length; i++) {
            if(fonts[i].tokenId != tokenId) { continue; }
            delete _fontOwner[tokenId];
            _fonts[from][i] = _fonts[from][fonts.length - 1];
            _fonts[from].pop();
            break;
        }
    }    

    function onERC721Received(address, address, uint256, bytes calldata) pure external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: Unlicense
//Company: sandollmetalab, 2022/04/30
//Writer: Super Moon
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Minter is Context {
    address internal _minter;

    event MinterTransferred(address indexed previousMinter, address indexed newMinter);

    constructor() {
        _transferMinter(_msgSender());
    }

    function minter() public view virtual returns (address) {
        return _minter;
    }

    modifier onlyMinter() {
        require(minter() == _msgSender(), "Minter: caller is not the minter");
        _;
    }

    function renounceMinter() public virtual onlyMinter {
        _transferMinter(address(0));
    }

    function transferMinter(address newMinter) public virtual onlyMinter {
        require(newMinter != address(0), "Minter: new minter is the zero address");
        _transferMinter(newMinter);
    }

    function _transferMinter(address newMinter) internal virtual {
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterTransferred(oldMinter, newMinter);
    }
}

abstract contract MintController is Ownable, Minter {

    uint256 internal _mintPrice;

    event Minted (address indexed from, address indexed to, uint256 tokenId, string tokenURI);
    event MintApproved (address indexed from, address indexed to, uint256 tokenId, uint256 count, bool combined);
    event DecombineApproved (address indexed from, uint256 tokenId);

    constructor(address recipient) { _minter = recipient; }

    function setMintPrice(uint256 price) external onlyMinter {
        _mintPrice = price;
    }

    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    function getTotalMintPrice(uint256 count) external view returns (uint256) {
        require(count > 0, "count should be bigger than 0");
        return _mintPrice + count;
    }

    function mint(address recipient, uint256 tokenId, string memory tokenURI) virtual external onlyMinter {}
    function approveMint(uint256 count) virtual external payable {}
    function approveCombine(uint256 idx) virtual external {}
}

//SPDX-License-Identifier: Unlicense
//Company: sandollmetalab, 2022/04/30
//Writer: Super Moon
pragma solidity ^0.8.12;

struct Font {
    uint256 tokenId;
    uint16 ftype;
    uint16 edition;
    uint256 idx;
    uint256 shift;
    string name;
    string sub;
    string image;
    string tokenURI;
    uint256[] reclaims;
}

struct FontOwner {
    address owner;
    Font font;
}

enum ListType {
    OG,
    Whitelist,
    None
}

//SPDX-License-Identifier: Unlicense
//Company: sandollmetalab, 2022/04/30
//Writer: Super Moon
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Controlable is Ownable {

    using Address for address;
    mapping (address => bool) _controllers;

    constructor() { _controllers[_msgSender()] = true; }

    modifier onlyControllers() {
        require(_controllers[_msgSender()] == true, "Sender is not controller.");
        _;
    }

    function addController(address controller) external {
        require(controller != address(0), "Address should not be null.");
        _controllers[controller] = true;
    }

    function removeController(address controller) external {
        require(controller != address(0), "Address should not be null.");
        _controllers[controller] = false;
        delete _controllers[controller];
    }    

    function isController(address controller) external view returns (bool) {
        require(controller != address(0), "Address should not be null.");
        return _controllers[controller];
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