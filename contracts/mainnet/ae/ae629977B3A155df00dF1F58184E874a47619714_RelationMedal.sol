// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../core/SemanticSBTCore.sol";
import "../../core/SemanticBaseStruct.sol";

contract RelationMedal is Ownable, Initializable,SemanticSBCore {
    using Strings for uint256;
    using Strings for address;

    struct Signature {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
    }


    bytes32 constant MINT_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000001;



    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public _ownedSBT;


    function isOwnerOf(address account,uint256 _pIndex,uint256 _oIndex)public view returns(bool){
        return _ownedSBT[account][_pIndex][_oIndex];
    }



    function claim(Signature memory signature, uint256 expireTime, uint256 _pIndex,uint256 _oIndex) external{
        require(!_ownedSBT[msg.sender][_pIndex][_oIndex], "You have successfully claimed it");
        require(expireTime > block.timestamp, "Signature data expired");
        string memory originalData = string.concat(
                address(this).toHexString(),
                msg.sender.toHexString(),
                expireTime.toString(),
                _pIndex.toString(),
                _oIndex.toString());
        address signer = _verifyMessage(
                keccak256(abi.encodePacked(originalData)),
                signature._v,
                signature._r,
                signature._s
            );
        require(minters(signer), "SignData exception. Plz join Relation official Discord to open a ticket for support >> https://discord.gg/qmG4AHK6U5");
        SubjectPO[] memory subjectPO = new SubjectPO[](1);
        subjectPO[0] = SubjectPO(_pIndex, _oIndex);

        _mint(msg.sender, 0, new IntPO[](0), new StringPO[](0), new AddressPO[](0),
                subjectPO, new BlankNodePO[](0));
        _ownedSBT[msg.sender][_pIndex][_oIndex] = true;
    }



    /**
     * @dev See {IERC165-supportsInterface}.
     *  ISemanticSBT 0xfbafb698
     *  ISemanticSBTMetadata 0x58e23bac
     *  ISemanticSBTOperator 0x9cd23707
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(SemanticSBCore) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(ISemanticSBT).interfaceId ||
        interfaceId == type(ISemanticSBTMetadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }




    function _verifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/ISemanticSBTMetadata.sol";

import "../interfaces/ISemanticSBT.sol";
import "./SemanticBaseStruct.sol";


/**
 * @dev Implement ISemanticSBT interface
 */
contract SemanticSBCore is Ownable, Initializable, ERC165, IERC721Enumerable, ISemanticSBT, ISemanticSBTMetadata {
    using Address for address;
    using Strings for uint256;
    using Strings for uint160;

    using Strings for address;

    /* ============ State Variables ============ */

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens burned
    uint256 private _burnCount;

    // Array of all tokens
    SPO[] private _tokens;

    // Mapping from owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // The operator of mint,burn and add subject
    mapping(address => bool) private _minters;

    // Default not allow transfer
    bool private _transferable;


    // Array of all subject
    Subject[] private _subjects;

    // Mapping from subject to subject index
    mapping(uint256 => mapping(string => uint256)) private _subjectIndex;

    // Base token URI 
    string private _baseURI;

    // Schema URI
    string public schemaURI;


    // Mapping from class name to class index
    mapping(string => uint256) private _classIndex;
    // Array of all class name
    string[] private _classNames;

    // Mapping from predicate name to predicate index
    mapping(string => uint256) private _predicateIndex;
    // Array of all Predicate
    Predicate[] private _predicates;


    // Array of all object value with string type
    string[] _stringO;
    // Array of all object value with BlankNodeO type 
    BlankNodeO[] _blankNodeO;

    /* ============ Constant Variable ============ */

    string  constant TURTLE_LINE_SUFFIX = " ;";
    string  constant TURTLE_END_SUFFIX = " . ";
    string  constant SOUL_CLASS_NAME = "Soul";


    string  constant ENTITY_PREFIX = ":";
    string  constant PROPERTY_PREFIX = "p:";

    string  constant CONCATENATION_CHARACTER = "_";
    string  constant BLANK_NODE_START_CHARACTER = "[";
    string  constant BLANK_NODE_END_CHARACTER = "]";
    string  constant BLANK_SPACE = " ";

    /* ============ Events ============ */
    // Add new minter
    event EventMinterAdded(address indexed newMinter);

    // Remove old minter
    event EventMinterRemoved(address indexed oldMinter);

    /* ============ Modifiers ============ */

    /**
     * Only minter.
     */
    modifier onlyMinter() {
        require(_minters[msg.sender], "SemanticSBT: must be minter");
        _;
    }

    /**
     * Only allow transfer.
     */
    modifier onlyTransferable() {
        require(_transferable, "SemanticSBT: must transferable");
        _;
    }

    /**
     * @dev Initializes the contract
     */
    constructor() {
        // Initialize zero index value
        SPO memory _spo = SPO(0, 0, new uint256[](0), new uint256[](0));
        Subject memory _subject = Subject("", 0);
        _tokens.push(_spo);
        _subjects.push(_subject);

        _classNames.push("");
        _predicates.push(Predicate("", FieldType.INT));
    }

    function initialize(
        address minter,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory schemaURI_,
        string[] memory classes_,
        Predicate[] memory predicates_
    ) public initializer onlyOwner {
        require(keccak256(abi.encode(schemaURI_)) != keccak256(abi.encode("")), "SemanticSBT: schema URI cannot be empty");
        require(predicates_.length > 0, "SemanticSBT: predicate can not be empty");

        _minters[minter] = true;
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        schemaURI = schemaURI_;

        _addClass(classes_);
        _addPredicate(predicates_);
        emit EventMinterAdded(minter);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     *  ISemanticSBT 0xfbafb698
     *  ISemanticSBTMetadata 0x58e23bac
     *  ISemanticSBTOperator 0x9cd23707
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(ISemanticSBT).interfaceId ||
        interfaceId == type(ISemanticSBTMetadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev Is this address a minters.
     */
    function minters(address account) public view returns (bool) {
        return _minters[account];
    }

    /**
     * @dev See {ISemanticSBTOperator-transferable}.
     * Is this contract allow nft transfer.
     */
    function transferable() public view returns (bool) {
        return _transferable;
    }

    /**
     * @dev Returns the base URI for nft.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }


    /**
      * @dev Get class index
     */
    function classIndex(string memory className_) public view returns (uint256 classIndex_) {
        classIndex_ = _classIndex[className_];
    }

    /**
      * @dev Get class name
     */
    function className(uint256 cIndex) public view returns (string memory name_) {
        require(cIndex > 0 && cIndex < _classNames.length, "SemanticSBT: class not exist");
        name_ = _classNames[cIndex];
    }

    /**
     * @dev Get predicate index
     */
    function predicateIndex(string memory predicateName_) public view returns (uint256 predicateIndex_) {
        predicateIndex_ = _predicateIndex[predicateName_];
    }

    /**
     * @dev Get predicate
     */
    function predicate(uint256 pIndex) public view returns (string memory name_, FieldType fieldType) {
        require(pIndex > 0 && pIndex < _predicates.length, "SemanticSBT: predicate not exist");

        Predicate memory predicate_ = _predicates[pIndex];
        name_ = predicate_.name;
        fieldType = predicate_.fieldType;
    }

    /**
     * @dev Get subject index
     */
    function subjectIndex(string memory subjectValue, string memory className_) public view returns (uint256){
        uint256 sIndex = _subjectIndex[_classIndex[className_]][subjectValue];
        require(sIndex > 0, "SemanticSBT: does not exist");
        return sIndex;
    }

    /**
     * @dev Get subject
     */
    function subject(uint256 index) public view returns (string memory subjectValue, string memory className_){
        require(index > 0 && index < _subjects.length, "SemanticSBT: does not exist");
        subjectValue = _subjects[index].value;
        className_ = _classNames[_subjects[index].cIndex];
    }

    /**
     * @dev Get token rdf
     */
    function rdfOf(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "SemanticSBT: SemanticSBT does not exist");
        return _buildRDF(_tokens[tokenId]);
    }

    /**
     * @dev Get  number of minted
     */
    function getMinted() public view returns (uint256) {
        return _tokens.length - 1;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return getMinted() - _burnCount;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This is implementation is O(n) and should not be
     * called by other contracts.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _tokens.length; i++) {
            if (address(_tokens[i].owner) == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This is implementation is O(n) and should not be
     * called by other contracts.
     */
    function tokenByIndex(uint256 index)
    public
    view
    returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _tokens.length; i++) {
            if (_tokens[i].owner != 0) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: token index out of bounds");
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    override
    returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
    public
    view
    override
    returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: owner query for nonexistent token"
        );
        return address(_tokens[tokenId].owner);
    }

    /**
     * @dev See {ISemanticSBT-isOwnerOf}.
     */
    function isOwnerOf(address account, uint256 id)
    public
    view
    returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
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
    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
        bytes(_baseURI).length > 0
        ? string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"))
        : "";
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
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
    function getApproved(uint256 tokenId)
    public
    view
    override
    returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override {
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
    ) public onlyTransferable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens  existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= getMinted() && _tokens[tokenId].owner != 0x0;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
    }



    /**
     * @dev add class
     * @param classList the class array
     */
    function _addClass(string[] memory classList) internal {
        for (uint256 i = 0; i < classList.length; i++) {
            string memory className_ = classList[i];
            require(
                keccak256(abi.encode(className_)) != keccak256(abi.encode("")),
                "SemanticSBT: Class cannot be empty"
            );
            require(_classIndex[className_] == 0, "SemanticSBT: already added");
            _classNames.push(className_);
            _classIndex[className_] = _classNames.length - 1;
        }
    }

    /**
     * @dev add predicate
     * @param predicates the predicate array
     */
    function _addPredicate(Predicate[] memory predicates) internal {
        for (uint256 i = 0; i < predicates.length; i++) {
            Predicate memory predicate_ = predicates[i];
            require(
                keccak256(abi.encode(predicate_.name)) !=
                keccak256(abi.encode("")),
                "SemanticSBT: predicate cannot be empty"
            );
            require(_predicateIndex[predicate_.name] == 0, "SemanticSBT: already added");
            _predicates.push(predicate_);
            _predicateIndex[predicate_.name] = _predicates.length - 1;
        }
    }


    function _addIntPO(uint256[] storage pIndex, uint256[] storage oIndex, IntPO[] memory intPOList) internal {
        for (uint256 i = 0; i < intPOList.length; i++) {
            IntPO memory intPO = intPOList[i];
            _checkPredicate(intPO.pIndex, FieldType.INT);
            pIndex.push(intPO.pIndex);
            oIndex.push(intPO.o);
        }
    }

    function _addStringPO(uint256[] storage pIndex, uint256[] storage oIndex, StringPO[] memory stringPOList) internal {
        for (uint256 i = 0; i < stringPOList.length; i++) {
            StringPO memory stringPO = stringPOList[i];
            _checkPredicate(stringPO.pIndex, FieldType.STRING);
            uint256 _oIndex = _stringO.length;
            _stringO.push(stringPO.o);
            pIndex.push(stringPO.pIndex);
            oIndex.push(_oIndex);
        }
    }

    function _addAddressPO(uint256[] storage pIndex, uint256[] storage oIndex, AddressPO[] memory addressPOList) internal {
        for (uint256 i = 0; i < addressPOList.length; i++) {
            AddressPO memory addressPO = addressPOList[i];
            _checkPredicate(addressPO.pIndex, FieldType.ADDRESS);
            pIndex.push(addressPO.pIndex);
            oIndex.push(uint160(addressPO.o));
        }
    }

    function _addSubjectPO(uint256[] storage pIndex, uint256[] storage oIndex, SubjectPO[] memory subjectPOList) internal {
        for (uint256 i = 0; i < subjectPOList.length; i++) {
            SubjectPO memory subjectPO = subjectPOList[i];
            _checkPredicate(subjectPO.pIndex, FieldType.SUBJECT);
            require(subjectPO.oIndex > 0 && subjectPO.oIndex < _subjects.length, "SemanticSBT: subject not exist");
            pIndex.push(subjectPO.pIndex);
            oIndex.push(subjectPO.oIndex);
        }
    }

    function _addBlankNodePO(uint256[] storage pIndex, uint256[] storage oIndex, BlankNodePO[] memory blankNodePOList) internal {
        for (uint256 i = 0; i < blankNodePOList.length; i++) {
            BlankNodePO memory blankNodePO = blankNodePOList[i];
            require(blankNodePO.pIndex < _predicates.length, "SemanticSBT: predicate not exist");

            uint256 _blankNodeOIndex = _blankNodeO.length;
            _blankNodeO.push(BlankNodeO(new uint256[](0), new uint256[](0)));
            uint256[] storage blankNodePIndex = _blankNodeO[_blankNodeOIndex].pIndex;
            uint256[] storage blankNodeOIndex = _blankNodeO[_blankNodeOIndex].oIndex;

            _addIntPO(blankNodePIndex, blankNodeOIndex, blankNodePO.intO);
            _addStringPO(blankNodePIndex, blankNodeOIndex, blankNodePO.stringO);
            _addAddressPO(blankNodePIndex, blankNodeOIndex, blankNodePO.addressO);
            _addSubjectPO(blankNodePIndex, blankNodeOIndex, blankNodePO.subjectO);

            pIndex.push(blankNodePO.pIndex);
            oIndex.push(_blankNodeOIndex);
        }
    }

    function _buildRDF(SPO memory spo) internal view returns (string memory _rdf){
        _rdf = _buildS(spo);

        for (uint256 i = 0; i < spo.pIndex.length; i++) {
            Predicate memory p = _predicates[spo.pIndex[i]];
            if (FieldType.INT == p.fieldType) {
                _rdf = string.concat(_rdf, _buildIntRDF(spo.pIndex[i], spo.oIndex[i]));
            } else if (FieldType.STRING == p.fieldType) {
                _rdf = string.concat(_rdf, _buildStringRDF(spo.pIndex[i], spo.oIndex[i]));
            } else if (FieldType.ADDRESS == p.fieldType) {
                _rdf = string.concat(_rdf, _buildAddressRDF(spo.pIndex[i], spo.oIndex[i]));
            } else if (FieldType.SUBJECT == p.fieldType) {
                _rdf = string.concat(_rdf, _buildSubjectRDF(spo.pIndex[i], spo.oIndex[i]));
            } else if (FieldType.BLANKNODE == p.fieldType) {
                _rdf = string.concat(_rdf, _buildBlankNodeRDF(spo.pIndex[i], spo.oIndex[i]));
            }
            string memory suffix = i == spo.pIndex.length - 1 ? "." : ";";
            _rdf = string.concat(_rdf, suffix);
        }
    }

    function _buildS(SPO memory spo) internal view returns (string memory){
        string memory _className = spo.sIndex == 0 ? SOUL_CLASS_NAME : _classNames[spo.sIndex];
        string memory subjectValue = spo.sIndex == 0 ? address(spo.owner).toHexString() : _subjects[spo.sIndex].value;
        return string.concat(ENTITY_PREFIX, _className, CONCATENATION_CHARACTER, subjectValue, BLANK_SPACE);
    }

    function _buildIntRDF(uint256 pIndex, uint256 oIndex) internal view returns (string memory){
        Predicate memory predicate_ = _predicates[pIndex];
        string memory p = string.concat(PROPERTY_PREFIX, predicate_.name);
        string memory o = oIndex.toString();
        return string.concat(p, BLANK_SPACE, o);
    }

    function _buildStringRDF(uint256 pIndex, uint256 oIndex) internal view returns (string memory){
        Predicate memory predicate_ = _predicates[pIndex];
        string memory p = string.concat(PROPERTY_PREFIX, predicate_.name);
        string memory o = string.concat('"', _stringO[oIndex], '"');
        return string.concat(p, BLANK_SPACE, o);
    }

    function _buildAddressRDF(uint256 pIndex, uint256 oIndex) internal view returns (string memory){
        Predicate memory predicate_ = _predicates[pIndex];
        string memory p = string.concat(PROPERTY_PREFIX, predicate_.name);
        string memory o = string.concat(ENTITY_PREFIX, SOUL_CLASS_NAME, CONCATENATION_CHARACTER, address(uint160(oIndex)).toHexString());
        return string.concat(p, BLANK_SPACE, o);
    }


    function _buildSubjectRDF(uint256 pIndex, uint256 oIndex) internal view returns (string memory){
        Predicate memory predicate_ = _predicates[pIndex];
        string memory _className = _classNames[_subjects[oIndex].cIndex];
        string memory p = string.concat(PROPERTY_PREFIX, predicate_.name);
        string memory o = string.concat(ENTITY_PREFIX, _className, CONCATENATION_CHARACTER, _subjects[oIndex].value);
        return string.concat(p, BLANK_SPACE, o);
    }


    function _buildBlankNodeRDF(uint256 pIndex, uint256 oIndex) internal view returns (string memory){
        Predicate memory predicate_ = _predicates[pIndex];
        string memory p = string.concat(PROPERTY_PREFIX, predicate_.name);

        uint256[] memory blankPList = _blankNodeO[oIndex].pIndex;
        uint256[] memory blankOList = _blankNodeO[oIndex].oIndex;

        string memory _rdf = "";
        for (uint256 i = 0; i < blankPList.length; i++) {
            Predicate memory _p = _predicates[blankPList[i]];
            if (FieldType.INT == _p.fieldType) {
                _rdf = string.concat(_rdf, _buildIntRDF(blankPList[i], blankOList[i]));
            } else if (FieldType.STRING == _p.fieldType) {
                _rdf = string.concat(_rdf, _buildStringRDF(blankPList[i], blankOList[i]));
            } else if (FieldType.ADDRESS == _p.fieldType) {
                _rdf = string.concat(_rdf, _buildAddressRDF(blankPList[i], blankOList[i]));
            } else if (FieldType.SUBJECT == _p.fieldType) {
                _rdf = string.concat(_rdf, _buildSubjectRDF(blankPList[i], blankOList[i]));
            }
            if (i < blankPList.length - 1) {
                _rdf = string.concat(_rdf, TURTLE_LINE_SUFFIX);
            }
        }

        return string.concat(p, BLANK_SPACE, BLANK_NODE_START_CHARACTER, _rdf, BLANK_NODE_END_CHARACTER);
    }


    function _checkPredicate(uint256 pIndex, FieldType fieldType) internal view {
        require(pIndex > 0 && pIndex < _predicates.length, "SemanticSBT: predicate not exist");
        require(_predicates[pIndex].fieldType == fieldType, "SemanticSBT: predicate type error");
    }

    function _mint(address account, uint256 sIndex, IntPO[] memory intPOList, StringPO[] memory stringPOList,
        AddressPO[] memory addressPOList, SubjectPO[] memory subjectPOList,
        BlankNodePO[] memory blankNodePOList) internal returns (uint256) {
        require(account != address(0), "SemanticSBT: mint to the zero address");
        require(sIndex < _subjects.length, "SemanticSBT: param error");

        uint256 tokenId = _tokens.length;

        _tokens.push(SPO(uint160(account), sIndex, new uint256[](0), new uint256[](0)));
        uint256[] storage pIndex = _tokens[tokenId].pIndex;
        uint256[] storage oIndex = _tokens[tokenId].oIndex;

        _addIntPO(pIndex, oIndex, intPOList);
        _addStringPO(pIndex, oIndex, stringPOList);
        _addAddressPO(pIndex, oIndex, addressPOList);
        _addSubjectPO(pIndex, oIndex, subjectPOList);
        _addBlankNodePO(pIndex, oIndex, blankNodePOList);

        require(pIndex.length > 0, "SemanticSBT: param error");

        _balances[account] += 1;


        require(
            _checkOnERC721Received(address(0), account, tokenId, ""),
            "SemanticSBT: transfer to non ERC721Receiver implementer"
        );
        emit Transfer(address(0), account, tokenId);
        emit CreateSBT(msg.sender, account, tokenId, _buildRDF(_tokens[tokenId]));

        return tokenId;
    }

    /* ============ External Functions ============ */


    function addSubject(string memory value, string memory className_) external onlyMinter returns (uint256 sIndex) {
        uint256 cIndex = _classIndex[className_];
        require(cIndex > 0, "SemanticSBT: param error");
        require(_subjectIndex[cIndex][value] == 0, "SemanticSBT: already added");
        sIndex = _subjects.length;
        _subjectIndex[cIndex][value] = sIndex;
        _subjects.push(Subject(value, cIndex));
    }

    
    function mint(address account, uint256 sIndex, IntPO[] memory intPOList, StringPO[] memory stringPOList,
        AddressPO[] memory addressPOList, SubjectPO[] memory subjectPOList,
        BlankNodePO[] memory blankNodePOList) 
    external
    onlyMinter returns (uint256) {
        
        return _mint(account, sIndex, intPOList, stringPOList, addressPOList, subjectPOList, blankNodePOList);
    }

    function burn(address account, uint256 id) external onlyMinter {
        require(
            _isApprovedOrOwner(_msgSender(), id),
            "SemanticSBT: caller is not approved or owner"
        );
        require(isOwnerOf(account, id), "SemanticSBT: not owner");
        string memory _rdf = _buildRDF(_tokens[id]);
        // Clear approvals
        _approve(address(0), id);
        _burnCount++;
        _balances[account] -= 1;
        _tokens[id].owner = 0;

        emit Transfer(account, address(0), id);
        emit RemoveSBT(msg.sender, account, id, _rdf);
    }

    function burnBatch(address account, uint256[] calldata ids)
    external
    onlyMinter
    {
        _burnCount += ids.length;
        _balances[account] -= ids.length;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "SemanticSBT: caller is not approved or owner"
            );
            require(isOwnerOf(account, tokenId), "SemanticSBT: not owner");
            string memory _rdf = _buildRDF(_tokens[tokenId]);

            // Clear approvals
            _approve(address(0), tokenId);
            _tokens[tokenId].owner = 0;

            emit Transfer(account, address(0), tokenId);
            emit RemoveSBT(msg.sender, account, tokenId, _rdf);
        }
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
        require(
            isOwnerOf(from, tokenId),
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokens[tokenId].owner = uint160(to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
            try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                    "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /* ============ Util Functions ============ */
    /**
     * @dev Sets a new baseURI for all token types.
     */
    function setURI(string calldata newURI) external onlyOwner {
        _baseURI = newURI;
    }

    /**
     * @dev Sets a new transferable for all token types.
     */
    function setTransferable(bool transferable_) external onlyOwner {
        _transferable = transferable_;
    }

    /**
     * @dev Sets a new name for all token types.
     */
    function setName(string calldata newName) external onlyOwner {
        _name = newName;
    }

    /**
     * @dev Sets a new symbol for all token types.
     */
    function setSymbol(string calldata newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }

    /**
     * @dev Add a new minter.
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "SemanticSBT: minter must not be null address");
        require(!_minters[minter], "SemanticSBT: minter already added");
        _minters[minter] = true;
        emit EventMinterAdded(minter);
    }

    /**
     * @dev Remove a old minter.
     */
    function removeMinter(address minter) external onlyOwner {
        require(_minters[minter], "SemanticSBT: minter does not exist");
        delete _minters[minter];
        emit EventMinterRemoved(minter);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum FieldType {
    INT,
    STRING,
    ADDRESS,
    SUBJECT,
    BLANKNODE
}

struct IntPO {
    uint256 pIndex;
    uint256 o;
}

struct StringPO {
    uint256 pIndex;
    string o;
}

struct AddressPO {
    uint256 pIndex;
    address o;
}

struct SubjectPO {
    uint256 pIndex;
    uint256 oIndex;
}

struct BlankNodePO {
    uint256 pIndex;
    IntPO[] intO;
    StringPO[] stringO;
    AddressPO[] addressO;
    SubjectPO[] subjectO;
}

struct BlankNodeO {
    uint256[] pIndex;
    uint256[] oIndex;
}

struct SPO {
    uint160 owner;
    uint256 sIndex;
    uint256[] pIndex;
    uint256[] oIndex;
}

struct Class {
    uint256 index;
    string name;
}

struct Predicate {
    string name;
    FieldType fieldType;
}

struct Subject {
    string value;
    uint256 cIndex;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an ISemanticData compliant contract.
 */
interface ISemanticSBT is IERC721 {


    event CreateSBT(
        address indexed operator,
        address indexed owner,
        uint256 indexed tokenId,
        string rdf
    );

    event RemoveSBT(
        address indexed operator,
        address indexed owner,
        uint256 indexed tokenId,
        string rdf
    );


    /**
     * @dev returns formatted rdf data
     * @param tokenId The token Id
     */
    function rdfOf(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ISemanticSBTMetadata is IERC721Metadata {

    /**
     * @dev Returns the Uniform Resource Identifier [URI](https://www.ietf.org/rfc/rfc3986.txt) for semantic metadata
     */
    function schemaURI() external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}