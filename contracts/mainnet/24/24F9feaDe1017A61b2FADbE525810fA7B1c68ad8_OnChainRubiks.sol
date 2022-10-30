// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/*############################################################################################*\
#                                                                                              #
#      10    01       .01110011.      .01100101.      .01100001. 100        011 .01100101.     #
#    1010    0101    010101001010    010010110110    101010010100  010    110  010100100100    #
#   0100      0101  1010            0110      1001            0110  010  010  0110      0010   #
#  0101        1100101011001010100101010101001011010100101001010010'01111000'0110100101101010  #
#   1000      0010            0110  0010            0010      0110  010  000  0110             #
#    001101010100    011011010100    0110101010110   010100101010  011    101  011011100010    #
#     '01110101'      '01110011'      '01100101'      '01100001' 010        010 '01100101'     #
#                                                                                              #
#    This smart contract was generate and store rubiks patterns 100% on blockchain.            #
#    It's amazing many awesome rubiks patterns and Do It Yourself create your pattern.         #
#                                                                                              #
#    Let's play together.                                                                      #
#                                                                                              #
#    onChainRubik's generator by @useaxes212                                                   #
#                                                                                              #
\*############################################################################################*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GetOCR.sol";

contract OnChainRubiks is 
    ERC721,
    ERC2981,
    ERC721Enumerable,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard
    {
    uint256 public maxSupply;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    struct ConfCost{
        uint256 oCRGenerateCost;    // cost to generate (to get point)
        uint256 oCRScrambleCost;    // cost to scramble pattern
        uint16  oCRMultiple;        // multiple every scramble notation pattern
        uint16  oCRMinHolder;       // minimal holder can generate pattern
        uint16  oCRScramblePoint;   // number of points each generate
        }

    struct Rubik {
        string name;        // name rubiks pattern
        string scramble;    // notations pattern
        string dna;         // dna unique patttern
        address createdby;  // creator/minter pattern
        bool random;        // proccess status
    }

    struct oCRGenerate{
        uint16 amount;     // total point generate
        uint16 scramble;   // used scramble notation points 
    }

    struct Dna {
        bool exist;
    }
    mapping(uint256 => Rubik) public rubiks;
    mapping(string  => Dna) public isDna;    
    mapping(address => oCRGenerate) public generate;
    ConfCost public confcost;

    constructor() ERC721("onChainRubiks", "oCR") {
        maxSupply = 1000;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete rubiks[tokenId];
    }

    function setConf(uint256 _oCRGenerateCost, 
                     uint256 _oCRScrambleCost, 
                     uint16  _oCRMultiple,
                     uint16  _oCRMinHolder,
                     uint16  _oCRScramblePoint,
                     uint256 _maxSupply
                     ) public onlyOwner {
        confcost.oCRGenerateCost = _oCRGenerateCost;
        confcost.oCRScrambleCost = _oCRScrambleCost;
        confcost.oCRMultiple = _oCRMultiple;
        confcost.oCRMinHolder = _oCRMinHolder;
        confcost.oCRScramblePoint = _oCRScramblePoint;    
        require(_maxSupply > totalSupply(), "Maxsupply must > totalSupply!");
        maxSupply = _maxSupply;
    }

    // Verify create token
    // create token until maxSupply
    // can generate if user have token >= confcost.oCRMinHolder and insufficient point   
    // user can create pattern if sufficient point (oCRGenerate.amount  > oCRGenerate.scramble + confcost.oCRMultiple)
    // sufficient funds
    // _generate = true : mintVerify to _mintRandom
    // _generate = false: mintVerify to _mintRubik
    function mintVerify(bool _generate) private {
        require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
        if(_msgSender()!= owner() ){
            require( balanceOf(msg.sender) >= confcost.oCRMinHolder , "inValid MinHolder!");
            if(_generate == false){
                require(generate[_msgSender()].scramble + confcost.oCRMultiple <= generate[_msgSender()].amount , "inValid point!");
                require(msg.value  >= (confcost.oCRScrambleCost/1000) * 1e18 , "Insufficient funds!");
            }else{
                require(generate[_msgSender()].scramble + confcost.oCRMultiple > generate[_msgSender()].amount , "inValid point!");
                require(msg.value  >= (confcost.oCRGenerateCost/1000) * 1e18 , "Insufficient funds!");
            }
        }
    }

    // validation pattern notations and name
    modifier isNotations(string memory _notation, string memory _name, uint _namelength ) {
        require(GetOCR.notationsCheck(_notation, _name, _namelength)==true, "invalid notations!");
        _;
    }

    function _mintRubik(string memory _name, string memory _scramble) public isNotations(_scramble,_name,25) payable {        
        mintVerify(false);
        string memory dna = GetOCR.getDna(_scramble);
        require(isDna[dna].exist!=true, "Dna exists!");
        rubiks[_tokenIdTracker.current()] = Rubik(string(abi.encodePacked("oCR#",Strings.toString(_tokenIdTracker.current())," ", _name)), _scramble, dna, _msgSender(), false);
        isDna[dna] = Dna(true);
        _safeMint(_msgSender(), _tokenIdTracker.current());        
        if(_msgSender()!= owner() ){
            generate[_msgSender()].scramble = generate[_msgSender()].scramble + confcost.oCRMultiple;            
        }
        _setTokenRoyalty(_tokenIdTracker.current(), _msgSender(), 500);        
        _tokenIdTracker.increment();
    }

    function _mintRandom() public  payable {
        mintVerify(true);
        string memory _scramble = GetOCR.randomNotations(_tokenIdTracker.current());
        string memory dna = GetOCR.getDna(_scramble);
        require(isDna[dna].exist!=true, "Dna exists!");
        rubiks[_tokenIdTracker.current()] = Rubik(string(abi.encodePacked("oCR#",Strings.toString(_tokenIdTracker.current()))), _scramble, dna, owner(), true);
        isDna[dna] = Dna(true);
        _safeMint(_msgSender(), _tokenIdTracker.current());
        _setTokenRoyalty(_tokenIdTracker.current(), owner(), 500);
        _tokenIdTracker.increment();
        if(_msgSender()!= owner() ){
            generate[_msgSender()].amount = generate[_msgSender()].amount + (confcost.oCRScramblePoint);            
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool useaxe, ) = payable(owner()).call{value: address(this).balance}("");
        require(useaxe);
    }

    function tokenURI(uint256 _tokenId) override(ERC721) public view returns (string memory) {
        return GetOCR.rubiksURI(
            _tokenId,
            rubiks[_tokenId].name,
            rubiks[_tokenId].scramble,
            rubiks[_tokenId].dna,
            rubiks[_tokenId].createdby
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
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

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
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
pragma solidity >=0.8.10 <0.9.0;

/*############################################################################################*\
#                                                                                              #
#      10    01       .01110011.      .01100101.      .01100001. 100        011 .01100101.     #
#    1010    0101    010101001010    010010110110    101010010100  010    110  010100100100    #
#   0100      0101  1010            0110      1001            0110  010  010  0110      0010   #
#  0101        1100101011001010100101010101001011010100101001010010'01111000'0110100101101010  #
#   1000      0010            0110  0010            0010      0110  010  000  0110             #
#    001101010100    011011010100    0110101010110   010100101010  011    101  011011100010    #
#     '01110101'      '01110011'      '01100101'      '01100001' 010        010 '01100101'     #
#                                                                                              #
#    This smart contract was generate and store rubiks patterns 100% on blockchain.            #
#    It's amazing many awesome rubiks patterns and Do It Yourself create your pattern.         #
#                                                                                              #
#    Let's play together.                                                                      #
#                                                                                              #
#    onChainRubik's generator by @useaxes212                                                   #
#                                                                                              #
\*############################################################################################*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./BaseRubiks.sol";

library GetOCR {
    function notationsCheck(string memory _notation, string memory _name, uint _namelength) public pure returns (bool) {
        string[18] memory notationsArr = ["F","U","R","B","D","L","M","S","E","f","u","r","b","d","l","m","s","e"];
        bool notation;
        bytes memory textcheck = bytes(_name);
        if(textcheck.length > _namelength) return false;
        for(uint i; i < textcheck.length; i++){
            bytes1 char = textcheck[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) && //space
                !(char == 0x2E) && //.
                !(char == 0x2D) //-
            )
                return false;
        }        
        for(uint i=0;i < bytes(_notation).length ;i++){
            bytes32  notationKey = keccak256(abi.encodePacked(bytes(_notation)[i]));
            notation = false;
            for (uint j=0; j < notationsArr.length; j++) {
                if (notationKey == keccak256(abi.encodePacked(bytes(notationsArr[j])))) {
                    notation = true;
                    break;
                }
            }
            if(!notation) break;
        }
        return (notation);
    }

    // check string only alphanumeric
    function stringCheck(string memory _text, uint256 _textlength) public pure returns (bool){
        bytes memory textcheck = bytes(_text);
        if(textcheck.length > _textlength) return false;
        for(uint i; i < textcheck.length; i++){
            bytes1 char = textcheck[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) //.
            )
                return false;
        }
        return true;
    }

    function getRubiks(uint256 _tokenId, string[2][54] memory getnewposes) public pure returns (string memory) {
        string[54] memory piecepaths = BaseRubiks.piecePath();
        string memory beginSvg = string(abi.encodePacked("<svg width='512' height='512' version='1.0' id='onChainRubiks-",Strings.toString(_tokenId),"'  xmlns='http://www.w3.org/2000/svg' xmlns:svg='http://www.w3.org/2000/svg'><path id='BACKGROUND' style='fill:#222222;stroke-width:0' d='M 5e-7,5e-7 H 512 V 512 H 5e-7 Z'/> <g id='RUBIK' style='stroke:#222222;stroke-width:2;stroke-linejoin:round;stroke-miterlimit:4' transform='' >"));
        string memory pathSvg;
        for (uint i=0; i < 54; i++) {
            pathSvg = string(abi.encodePacked(pathSvg,"<path id='p",Strings.toString(i),"' style='fill:",getnewposes[i][0],"' ",piecepaths[i],"/> "));
        }
        string memory endSvg = "</g></svg>";
        string memory rubikSvg = string(abi.encodePacked(beginSvg,pathSvg,endSvg));
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(rubikSvg));
        return string(abi.encodePacked(baseURL, svgBase64Encoded)); 
    }

    function getDna(string memory _notation) public pure returns (string memory) {
        string[2][54] memory getnewposes = scramble(_notation);
        string memory _dna;
        for (uint i=0; i < 54; i++) {
            _dna = string(abi.encodePacked(_dna, getnewposes[i][1]));
        }
        return (_dna);         
    }

    function scramble(string memory _notation) public pure returns (string[2][54] memory) {
        uint8[4][5] memory permutarr1;
        string[2][54] memory defpostmp1 = BaseRubiks.defPos();
        for(uint i=0;i < bytes(_notation).length ;i++){
            bool _ccw;
            bytes32  key = keccak256(abi.encodePacked(bytes(_notation)[i]));            
            if(key == keccak256("f") || key == keccak256("u") || key == keccak256("r") ||  
               key == keccak256("b") || key == keccak256("d") || key == keccak256("l") ||
               key == keccak256("m") || key == keccak256("s") || key == keccak256("e") 
            ){
               _ccw = true;
            }
            permutarr1 = BaseRubiks.permut(key); 
            if(_ccw == false){
               for(uint j=0; j <= 4; j++){
                  uint8  a1 = permutarr1[j][0];
                  uint8  b1 = permutarr1[j][1];
                  uint8  c1 = permutarr1[j][2];
                  uint8  d1 = permutarr1[j][3];
                  string[2] memory temp01 = defpostmp1[a1];
                  defpostmp1[a1] = defpostmp1[d1];
                  defpostmp1[d1] = defpostmp1[c1];
                  defpostmp1[c1] = defpostmp1[b1];
                  defpostmp1[b1] = temp01;
               }
            }
            if(_ccw == true ){
               for(uint k=0; k <= 4; k++){
                  uint8  a1 = permutarr1[k][3];
                  uint8  b1 = permutarr1[k][2];
                  uint8  c1 = permutarr1[k][1];
                  uint8  d1 = permutarr1[k][0];
                  string[2] memory temp02 = defpostmp1[a1];
                  defpostmp1[a1] = defpostmp1[d1];
                  defpostmp1[d1] = defpostmp1[c1];
                  defpostmp1[c1] = defpostmp1[b1];
                  defpostmp1[b1] = temp02;
               }
            }
        }
        return (defpostmp1);
    }

    function randomNotations(uint256 tokenId) public view returns (string memory notationstr) {
        string[12] memory notationsArr = ["F","U","R","B","D","L","f","u","r","b","d","l"];
        uint8 notationAmount = random();
        uint256[] memory notations = new uint256[](notationAmount);        
        for (uint256 i = 0; i < notationAmount; i++) {
            notations[i] = uint256(keccak256(abi.encodePacked(block.timestamp,tokenId, i)))%12;
            notationstr = string(abi.encodePacked(notationstr,notationsArr[notations[i]]));
        }        
        return (notationstr);
    }   

    function random() public view returns(uint8){
        uint8[5] memory _myArray = [16,17,18,19,20];
        uint a = _myArray.length; 
        uint b = _myArray.length;
        for(uint i = 0; i< b ; i++){
            uint randNumber =(uint(keccak256      
            (abi.encodePacked(block.timestamp,_myArray[i]))) % a)+1;
            uint8 interim = _myArray[randNumber - 1];
            _myArray[randNumber-1]= _myArray[a-1];
            _myArray[a-1] = interim;
            a = a-1;
        }
        uint8 result;
        result = _myArray[0];       
        return result;        
    }

    function rubiksURI( uint256 _tokenId,  
                        string memory _name, 
                        string memory _scramble,  
                        string memory _dna, 
                        address _createdby 
                        ) public pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', _name, '",',
                    '"description": "', _scramble, '",',
                    '"dna": "', _dna, '",',
                    '"fee_recipient": "', Strings.toHexString(uint256(uint160(_createdby)), 20) ,'",',
                    '"seller_fee_basis_points": 500 ,',
                    '"image_data": "', getRubiks(_tokenId, scramble(_scramble)), '"'
                   '}'
                )
            ))
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/*############################################################################################*\
#                                                                                              #
#      10    01       .01110011.      .01100101.      .01100001. 100        011 .01100101.     #
#    1010    0101    010101001010    010010110110    101010010100  010    110  010100100100    #
#   0100      0101  1010            0110      1001            0110  010  010  0110      0010   #
#  0101        1100101011001010100101010101001011010100101001010010'01111000'0110100101101010  #
#   1000      0010            0110  0010            0010      0110  010  000  0110             #
#    001101010100    011011010100    0110101010110   010100101010  011    101  011011100010    #
#     '01110101'      '01110011'      '01100101'      '01100001' 010        010 '01100101'     #
#                                                                                              #
#    This smart contract was generate and store rubiks patterns 100% on blockchain.            #
#    It's amazing many awesome rubiks patterns and Do It Yourself create your pattern.         #
#                                                                                              #
#    Let's play together.                                                                      #
#                                                                                              #
#    onChainRubik's generator by @useaxes212                                                   #
#                                                                                              #
\*############################################################################################*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
library BaseRubiks {
    function piecePath() public pure returns (string[54] memory) {
        string[54] memory piecepaths =["d='m 138.97058,268.38342 v -44.945 l 38.9235,22.4725 v 44.945 z'", "d='m 177.89408,290.85592 v -44.945 l 38.9235,22.47251 v 44.94499 z'", "d='m 216.81758,313.32843 v -44.945 l 38.9235,22.4725 v 44.945 z'", "d='m 138.97059,313.3284 v -44.945 l 38.92349,22.47251 v 44.94499 z'", "d='m 177.89409,335.80091 v -44.945 l 38.9235,22.4725 v 44.94499 z'", "d='m 216.81759,358.27341 v -44.945 l 38.9235,22.47251 v 44.94499 z'", "d='m 138.97059,358.2734 v -44.94501 l 38.92349,22.47251 v 44.94499 z'", "d='m 177.89409,380.7459 v -44.945 l 38.9235,22.4725 v 44.945 z'", "d='M 216.81759,403.21841 V 358.2734 l 38.9235,22.47251 v 44.94499 z'",
            "d='m 138.97058,223.43842 38.9235,-22.47247 38.92349,22.47247 -38.92349,22.4725 z'", "d='m 177.89407,200.96589 38.9235,-22.47247 38.92349,22.47247 -38.92349,22.47251 z'", "d='m 216.81759,178.4934 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.4725 z'", "d='m 177.8941,245.91093 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.47251 z'", "d='m 216.81759,223.43841 38.9235,-22.47247 38.92349,22.47247 -38.92349,22.4725 z'", "d='m 255.74111,200.96591 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.47251 z'", "d='m 216.8176,268.38343 38.9235,-22.47247 38.92349,22.47247 -38.92349,22.4725 z'", "d='m 255.74109,245.91091 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.4725 z'", "d='m 294.6646,223.43841 38.9235,-22.47247 38.9235,22.47247 -38.9235,22.4725 z'",
            "d='m 294.66458,313.32842 v -44.945 l -38.92349,22.4725 v 44.945 z'", "d='m 333.5881,290.85593 v -44.945 l -38.9235,22.47251 v 44.94499 z'", "d='m 372.5116,268.38343 v -44.945 l -38.92349,22.4725 v 44.94499 z'", "d='M 294.66459,358.27341 V 313.3284 l -38.92349,22.47251 v 44.94499 z'", "d='m 333.58811,335.80092 v -44.945 l -38.9235,22.4725 v 44.94499 z'", "d='m 372.51161,313.32841 v -44.945 l -38.92349,22.47251 v 44.94499 z'", "d='M 294.66459,403.21838 V 358.27339 L 255.7411,380.7459 v 44.945 z'", "d='m 333.58811,380.7459 v -44.94499 l -38.9235,22.4725 v 44.94501 z'", "d='M 372.51161,358.27341 V 313.3284 l -38.92349,22.47251 v 44.94499 z'",
            "d='m 378.98218,270.24061 v -44.945 l 38.9235,22.4725 v 44.94499 z'", "d='m 417.90569,292.71311 v -44.945 l 38.92349,22.47251 v 44.94499 z'", "d='m 456.82918,315.18562 v -44.945 l 38.9235,22.4725 v 44.94499 z'", "d='m 378.98219,315.18559 v -44.945 l 38.9235,22.4725 v 44.945 z'", "d='m 417.90569,337.6581 v -44.94501 l 38.9235,22.47251 v 44.94499 z'", "d='m 456.82919,360.1306 v -44.945 l 38.9235,22.4725 v 44.945 z'", "d='m 378.98219,360.13058 v -44.945 l 38.9235,22.47251 v 44.94499 z'", "d='m 417.90569,382.60309 v -44.945 l 38.9235,22.4725 v 44.94499 z'", "d='m 456.82919,405.07559 v -44.945 l 38.9235,22.47251 v 44.94499 z'",
            "d='m 16.247212,430.88271 38.923496,-22.47247 38.923496,22.47247 -38.923496,22.47251 z'", "d='m 55.170699,408.41019 38.923496,-22.47247 38.923495,22.47247 -38.923495,22.4725 z'", "d='m 94.094213,385.93769 38.923497,-22.47247 38.9235,22.47247 -38.9235,22.47251 z'", "d='m 55.170699,453.35519 38.923496,-22.47247 38.923495,22.47247 -38.923495,22.4725 z'", "d='m 94.094222,430.8827 38.923498,-22.47247 38.92349,22.47247 -38.92349,22.47251 z'", "d='m 133.01774,408.41021 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.4725 z'", "d='m 94.094231,475.82772 38.923499,-22.47247 38.92349,22.47247 -38.92349,22.47251 z'", "d='m 133.01772,453.3552 38.92349,-22.47247 38.9235,22.47247 -38.9235,22.4725 z'", "d='m 171.94123,430.8827 38.9235,-22.47247 38.92349,22.47247 -38.92349,22.47251 z'",
            "d='m 177.62628,103.58972 v -44.945 l -38.9235,22.472506 v 44.944994 z'", "d='M 216.54978,81.117217 V 36.172215 l -38.9235,22.472505 v 44.94499 z'", "d='M 255.47328,58.644711 V 13.69971 l -38.9235,22.472505 v 44.944993 z'", "d='M 177.62627,148.53471 V 103.5897 l -38.9235,22.47251 v 44.94499 z'", "d='M 216.54977,126.0622 V 81.117199 l -38.9235,22.472501 v 44.945 z'", "d='M 255.47327,103.58969 V 58.644694 l -38.92349,22.472505 v 44.944991 z'", "d='m 177.62627,193.4797 v -44.945 l -38.9235,22.4725 v 44.94499 z'", "d='m 216.54977,171.00719 v -44.945 l -38.9235,22.47251 v 44.94499 z'", "d='m 255.47327,148.53469 v -44.945 l -38.92349,22.4725 v 44.94499 z'"];
        return piecepaths;
    }

    function defPos() public pure returns (string[2][54] memory) {
        string[2][54] memory defpostmp = [
        ["#f44336","a"], ["#f44336","b"], ["#f44336","c"], ["#f44336","d"], ["#f44336","e"], ["#f44336","f"], ["#f44336","g"], ["#f44336","h"], ["#f44336","i"],
        ["#ffeb3b","j"], ["#ffeb3b","k"], ["#ffeb3b","l"], ["#ffeb3b","m"], ["#ffeb3b","n"], ["#ffeb3b","o"], ["#ffeb3b","p"], ["#ffeb3b","q"], ["#ffeb3b","r"],
        ["#4caf50","s"], ["#4caf50","t"], ["#4caf50","u"], ["#4caf50","v"], ["#4caf50","w"], ["#4caf50","x"], ["#4caf50","y"], ["#4caf50","z"], ["#4caf50","0"],
        ["#ff9800","A"], ["#ff9800","B"], ["#ff9800","C"], ["#ff9800","D"], ["#ff9800","E"], ["#ff9800","F"], ["#ff9800","G"], ["#ff9800","H"], ["#ff9800","I"],
        ["#ffffff","J"], ["#ffffff","K"], ["#ffffff","L"], ["#ffffff","M"], ["#ffffff","N"], ["#ffffff","O"], ["#ffffff","P"], ["#ffffff","Q"], ["#ffffff","R"],
        ["#2196f3","S"], ["#2196f3","T"], ["#2196f3","U"], ["#2196f3","V"], ["#2196f3","W"], ["#2196f3","X"], ["#2196f3","Y"], ["#2196f3","Z"], ["#2196f3","1"]
        ];
        return defpostmp;
    }
    
    // Permutation rubiks (face and center) 
    function permut(bytes32 _key ) public pure returns (uint8[4][5] memory) {
        uint8[4][5] memory _permut;
        //		            face permut cw          face permut ccw
        if(_key == keccak256("F") || _key == keccak256("f")){ _permut = [[ 0, 2, 8, 6],[ 1, 5, 7, 3],[ 9,18,42,51],[12,21,39,48],[15,24,36,45]]; }else 
        if(_key == keccak256("U") || _key == keccak256("u")){ _permut = [[ 9,11,17,15],[10,14,16,12],[45,27,20, 2],[46,28,19, 1],[47,29,18, 0]]; }else 
        if(_key == keccak256("R") || _key == keccak256("r")){ _permut = [[18,20,26,24],[19,23,25,21],[15,29,44, 8],[16,32,43, 5],[17,35,42, 2]]; }else 
        if(_key == keccak256("B") || _key == keccak256("b")){ _permut = [[29,27,33,35],[28,30,34,32],[17,47,38,26],[14,50,41,23],[11,53,44,20]]; }else 
        if(_key == keccak256("D") || _key == keccak256("d")){ _permut = [[36,42,44,38],[39,43,41,37],[ 6,24,35,53],[ 7,25,34,52],[ 8,26,33,51]]; }else 
        if(_key == keccak256("L") || _key == keccak256("l")){ _permut = [[47,45,51,53],[46,48,52,50],[11, 0,36,33],[10, 3,37,30],[ 9, 6,38,27]]; }else
        //		            center permut cw        center permut ccw
        if(_key == keccak256("M") || _key == keccak256("m")){ _permut = [[ 1,14,34,39],[ 4,13,31,40],[ 7,12,28,41],[ 0, 0, 0, 0],[ 0, 0, 0, 0]]; }else
        if(_key == keccak256("S") || _key == keccak256("s")){ _permut = [[10,19,43,52],[13,22,40,49],[16,25,37,46],[ 0, 0, 0, 0],[ 0, 0, 0, 0]]; }else
        if(_key == keccak256("E") || _key == keccak256("e")){ _permut = [[ 3,50,32,21],[ 4,49,31,22],[ 5,48,30,23],[ 0, 0, 0, 0],[ 0, 0, 0, 0]]; }            
        return (_permut);
    }
}