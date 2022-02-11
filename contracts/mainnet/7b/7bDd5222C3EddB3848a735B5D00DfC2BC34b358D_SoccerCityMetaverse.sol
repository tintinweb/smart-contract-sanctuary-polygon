/**
 *Submitted for verification at polygonscan.com on 2022-02-02
*/

//   /$$$$$$                                                     /$$$$$$  /$$   /$$              
//  /$$__  $$                                                   /$$__  $$|__/  | $$              
// | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
// |  $$$$$$  /$$__  $$ /$$_____/ /$$_____/ /$$__  $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
//  \____  $$| $$  \ $$| $$      | $$      | $$$$$$$$| $$  \__/| $$      | $$  | $$    | $$  | $$
//  /$$  \ $$| $$  | $$| $$      | $$      | $$_____/| $$      | $$    $$| $$  | $$ /$$| $$  | $$
// |  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$      |  $$$$$$/| $$  |  $$$$/|  $$$$$$$
//  \______/  \______/  \_______/ \_______/ \_______/|__/       \______/ |__/   \___/   \____  $$
//                                                                                      /$$  | $$
//                                                                                     |  $$$$$$/
//                                                                                      \______/ 
//  /$$      /$$             /$$                                                                 
// | $$$    /$$$            | $$                                                                 
// | $$$$  /$$$$  /$$$$$$  /$$$$$$    /$$$$$$  /$$    /$$ /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$  
// | $$ $$/$$ $$ /$$__  $$|_  $$_/   |____  $$|  $$  /$$//$$__  $$ /$$__  $$ /$$_____/ /$$__  $$ 
// | $$  $$$| $$| $$$$$$$$  | $$      /$$$$$$$ \  $$/$$/| $$$$$$$$| $$  \__/|  $$$$$$ | $$$$$$$$ 
// | $$\  $ | $$| $$_____/  | $$ /$$ /$$__  $$  \  $$$/ | $$_____/| $$       \____  $$| $$_____/ 
// | $$ \/  | $$|  $$$$$$$  |  $$$$/|  $$$$$$$   \  $/  |  $$$$$$$| $$       /$$$$$$$/|  $$$$$$$ 
// |__/     |__/ \_______/   \___/   \_______/    \_/    \_______/|__/      |_______/  \_______/ 
                                                                                                         
/*
#######################################################################################################################
#######################################################################################################################

Copyright CryptIT GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on aln "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

#######################################################################################################################
#######################################################################################################################

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;


library LibPart {
    
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }

}


//pragma abicoder v2;
interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}


abstract contract AbstractRoyalties {

    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

library LibRoyaltiesV2 {
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

//pragma abicoder v2;
contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
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

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

abstract contract ERC20Basic {
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address who) public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}                           

contract SoccerCityMetaverse is ERC721Enumerable, Ownable, RoyaltiesV2Impl {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _dataHostBaseURI = "ipfs://";
    string private _contractURI = "https://ipfs.io/ipfs/QmTv9Ux71peCxfuJvTo8cETVhrUhhz5zD5WnXDW3oMDmpy";
    string private _placeHolderHash = "ipfs://QmVgjUDERBQoPEBfNzqiHxmi9TbMv53WgPAfEkafCLcM6E";

    uint256 public maxMints = 20200;
    bool public publicBuyEnabled = false;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _finalizedTokens;
    mapping(ERC20 => uint256) private _tokenPrices;

    uint256[] private _batchSizes;
    string[] private _batchHashes;

    uint256 _price = 300000000000000000000;
    
    uint96 private _raribleRoyaltyPercentage = 500;
    address payable _beneficiary = payable(address(0xCec0A06D069e6Ba596F136bFA863125ac47aA2Ad));
    address payable _raribleBeneficiary = payable(address(0xCec0A06D069e6Ba596F136bFA863125ac47aA2Ad));

    address private batchOperator; 

    event BeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event RaribleBeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event BeneficiaryPaid(address payable beneficiary, uint256 amount, address token);
    event PriceChange(uint256 previousPrice, uint256 newPrice);
    event RaribleRoyaltyPercentageChange(uint96 previousPercentage, uint96 newPercentage);
    event BaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractBaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractURIChanged(string previousURI, string newURI);
    event PublicBuyEnabled(bool enabled);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor( string memory name, string memory symbol
    ) ERC721(name, symbol) Ownable() {
        emit BeneficiaryChanged(payable(address(0)), _beneficiary);
        emit RaribleBeneficiaryChanged(payable(address(0)), _raribleBeneficiary);
        emit RaribleRoyaltyPercentageChange(0, _raribleRoyaltyPercentage);
        
        batchOperator = owner();
    }

    function _mintToken(address owner) internal returns (uint) {

        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= maxMints, "Cannot mint more than max");

        _safeMint(owner, id);
        _setRoyalties(id, _raribleBeneficiary, _raribleRoyaltyPercentage);

        return id;
    }

    function mintToken() external payable returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");
        require(msg.value >= _price, "Invalid value sent");

        uint256 id = _mintToken(msg.sender);

        (bool sent, ) = _beneficiary.call{value : msg.value}("");
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, msg.value, address(0));

        return id;
    }

    function mintTokenWithERC20(ERC20 _ERC20Token) external returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");

        uint256 price = _tokenPrices[_ERC20Token];
        require(price != 0, "Token not supported");
        require(_ERC20Token.balanceOf(msg.sender) >= price, "Insufficient funds");
        require(_ERC20Token.allowance(msg.sender, address(this)) >= price, "Needs approval");

        uint256 id = _mintToken(msg.sender);

        bool sent = _ERC20Token.transferFrom(msg.sender, _beneficiary, price);
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, price, address(_ERC20Token));

        return id;
    }

    function mintMultipleTokenWithERC20(ERC20 _ERC20Token, uint256 count) external returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");

        uint256 price = _tokenPrices[_ERC20Token].mul(count);
        require(price != 0, "Token not supported");
        require(_ERC20Token.balanceOf(msg.sender) >= price, "Insufficient funds");
        require(_ERC20Token.allowance(msg.sender, address(this)) >= price, "Needs approval");

        for (uint256 i = 0; i < count; i++) {
            _mintToken(msg.sender);
        }

        bool sent = _ERC20Token.transferFrom(msg.sender, _beneficiary, price);
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, price, address(_ERC20Token));

        return count;
    }

    function mintMultipleToken(uint256 count) external payable returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");
        require(msg.value >= _price.mul(count), "Invalid value sent");

        for (uint256 i = 0; i < count; i++) {
            _mintToken(msg.sender);
        }

        (bool sent, ) = _beneficiary.call{value : msg.value}("");
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, msg.value, address(0));

        return count;
    }
    
    function airdrop(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i]);
        }
    }

    function mintMany(uint256 count, address receiver) external onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _mintToken(receiver);
        }
    }

    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    function setBeneficiary(address payable newBeneficiary) public onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new beneficiary is the zero address");
        address payable prev = _beneficiary;
        _beneficiary = newBeneficiary;
        emit BeneficiaryChanged(prev, _beneficiary);
    }

    function finalizeTokenURI(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exists yet");
        require(_finalizedTokens[tokenId] != true, "Token already finalized");
        _finalizedTokens[tokenId] = true;
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function setRaribleBeneficiary(address payable newBeneficiary) public onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new rarible beneficiary is the zero address");
        address payable prev = _raribleBeneficiary;
        _raribleBeneficiary = newBeneficiary;
        emit RaribleBeneficiaryChanged(prev, _raribleBeneficiary);
    }

    function getPrice() external view returns (uint256)  {
        return _price;
    }

    function setPrice(uint256 price) public onlyOwner {
        uint256 prev = _price;
        _price = price;
        emit PriceChange(prev, _price);
    }
    
    function setRaribleRoyaltyPercentage(uint96 percentage) public onlyOwner {
        uint96 prev = _raribleRoyaltyPercentage;
        _raribleRoyaltyPercentage = percentage;
        emit RaribleRoyaltyPercentageChange(prev, _raribleRoyaltyPercentage);
    }

    function setDataHostURI(string memory _URI) public onlyOwner {
        string memory prev = _dataHostBaseURI;
        _dataHostBaseURI = _URI;
        emit BaseURIChanged(prev, _dataHostBaseURI);
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        string memory prev = _contractURI;
        _contractURI = contractURI_;
        emit ContractURIChanged(prev, _contractURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _dataHostBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenURI_ = _tokenURIs[tokenId];
        if (bytes(tokenURI_).length > 0) {
            string memory base = _baseURI();
            return string(abi.encodePacked(base, tokenURI_));
        }

        return _getBatchHash(tokenId);
    }

    function _getBatchHash(uint256 tokenId) internal view returns (string memory){

        string memory base = _baseURI();
        if(tokenId == maxMints){
            base = string(abi.encodePacked(base, _batchHashes[_batchHashes.length -1]));
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
        for(uint256 i = 0; i < _batchSizes.length; i++){

            if(tokenId <= _batchSizes[i] && _tokenIds.current() > _batchSizes[i]){
                base = string(abi.encodePacked(base, _batchHashes[i]));
                return string(abi.encodePacked(base, Strings.toString(tokenId)));
            }
        }
        return _placeHolderHash;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) external onlyOwner {
        _setRoyalties(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) external onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        require(_finalizedTokens[tokenId] != true, "Token finalized, URI cannot be changed");
        _tokenURIs[tokenId] = tokenURI_;
    }
    
    function setPlaceHolderHash(string memory placeHolderHash) external onlyOwner {
        _placeHolderHash = placeHolderHash;
    }

    function enablePublicBuy(bool enabled) external onlyOwner {
        require(publicBuyEnabled != enabled, "Already set");
        publicBuyEnabled = enabled;
        emit PublicBuyEnabled(publicBuyEnabled);
    }
    
    function editBatchSize(uint256 batchIndex, uint256 batchSize, string memory batchHash) external onlyOwner {
        require(_batchSizes.length > batchIndex, "Index does not exist");
        _batchSizes[batchIndex] = batchSize;
        _batchHashes[batchIndex] = batchHash;
    }
    
    function _addBatchSize(uint256 batchSize, string memory batchHash) internal {
        _batchSizes.push(batchSize);
        _batchHashes.push(batchHash);
    }
    
    function addBatchSizes(uint256[] memory batchSizes, string[] memory batchHashes) external {
        require(msg.sender == owner() || msg.sender == batchOperator, "Unauthorized");
        for(uint256 i = 0; i < batchSizes.length; i++){
            _batchSizes.push(batchSizes[i]);
            _batchHashes.push(batchHashes[i]);
        }   
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    
    function addERC20Price(ERC20 token, uint256 price) external onlyOwner {
        _tokenPrices[token] = price;
    }
    
    function setBatchOperator(address operator) external onlyOwner {
        batchOperator = operator;
    }
}