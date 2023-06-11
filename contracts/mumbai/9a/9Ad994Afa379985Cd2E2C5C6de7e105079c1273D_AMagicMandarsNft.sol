/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC165                       {   function supportsInterface(bytes4 interfaceId) external view returns (bool); }
interface IERC1155Receiver  is IERC165  {   function onERC1155Received(address operator,address from,uint id,uint value,bytes calldata data) external returns (bytes4);
                                            function onERC1155BatchReceived(address operator,address from,uint[] calldata ids,uint[] calldata values,bytes calldata data) external returns (bytes4);
                                        }
interface IERC1155          is IERC165  {   event TransferSingle(address indexed operator, address indexed from, address indexed to, uint id, uint value);
                                            event TransferBatch(address indexed operator,address indexed from, address indexed to, uint[] ids, uint[] values);
                                            event ApprovalForAll(address indexed account, address indexed operator, bool approved);
                                            event URI(string value, uint indexed id);
                                            function balanceOf(address account, uint id) external view returns (uint);
                                            function balanceOfBatch(address[] calldata accounts, uint[] calldata ids) external view returns (uint[] memory);
                                            function setApprovalForAll(address operator, bool approved) external;
                                            function isApprovedForAll(address account, address operator) external view returns (bool);
                                            function safeTransferFrom(address from,address to,uint id,uint amount,bytes calldata data) external;
                                            function safeBatchTransferFrom(address from,address to,uint[] calldata ids,uint[] calldata amounts,bytes calldata data) external;
                                        }
interface IERC1155MetadataURI   is IERC1155 {   function uri(uint id) external view returns (string memory); }
abstract contract ERC165 is IERC165 { function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; } }
abstract contract Ownable { address private _owner; address private _admin;
    event   OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event   AdminChanged(address previousAdmin, address newAdmin);
    constructor ()    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        emit         AdminChanged(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {    return _owner;    }
    modifier onlyOwner() { require(owner() == msg.sender, "Ownable: caller is not the owner");        _;    }
}
library Address { function isContract(address account) internal view returns (bool) { return account.code.length > 0; } }
library Strings { bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";  uint8 private constant _ADDRESS_LENGTH = 20;
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint temp = value;        uint digits;
        while (temp != 0) {  digits++;  temp /= 10;  }
        bytes memory buffer = new bytes(digits);
        while (value != 0) { digits -= 1;  buffer[digits] = bytes1(uint8(48 + uint(value % 10))); value /= 10;  }
        return string(buffer);
}}
library Base64 
{
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;  if (len == 0) return "";
        uint encodedLen = 4 * ((len + 2) / 3);       // multiply by 4/3 rounded up
        bytes memory result = new bytes(encodedLen + 32);       // Add some extra buffer at the end
        bytes memory table = TABLE;
        assembly 
        {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for { let i := 0  } lt(i, len) { }  {
                i := add(i, 3)                let input := and(mload(add(data, i)), 0xffffff)                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))                out := shl(8, out)                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)                mstore(resultPtr, out)                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
                case 1 {                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))            }
                case 2 {                mstore(sub(resultPtr, 1), shl(248, 0x3d))            }
            mstore(result, encodedLen)
        }
        return string(result);
}}
library MerkleProof {
    function verify(bytes32[] memory proof,bytes32 root,bytes32 leaf) internal pure returns (bool) { return processProof(proof, leaf) == root; }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {computedHash = _hashPair(computedHash, proof[i]);}
        return computedHash;
    }
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) { return a < b ? _efficientHash(a, b) : _efficientHash(b, a); }
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {            mstore(0x00, a)            mstore(0x20, b)            value := keccak256(0x00, 0x40)        }
    }
}
contract ERC1155D is ERC165, IERC1155, IERC1155MetadataURI, Ownable 
{
    uint public constant MAX_SUPPLY = 5555;

    mapping(address => uint)    public     userNftQuantities;

    using Address for address;
    address[MAX_SUPPLY] internal _owners;

    mapping(address => mapping(address => bool)) private _operatorApprovals;    // Mapping from account to operator approvals
    string private _uri;                                                        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    constructor(string memory uri_)     {        _setURI(uri_);    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function uri(uint) public view virtual override returns (string memory) {
        return _uri;
    }
    function balanceOf(address account, uint id) public view virtual override returns (uint) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        require(id < MAX_SUPPLY, "ERC1155D: id exceeds maximum");

        return _owners[id] == account ? 1 : 0;
    }
    function balanceOfBatch(address[] memory accounts, uint[] memory ids)        public        view        virtual        override        returns (uint[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint[] memory batchBalances = new uint[](accounts.length);
        for (uint i = 0; i < accounts.length; ++i) {            batchBalances[i] = balanceOf(accounts[i], ids[i]);        }
        return batchBalances;
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {        _setApprovalForAll(msg.sender, operator, approved);    }
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {        return _operatorApprovals[account][operator];    }
    function safeTransferFrom(        address from,        address to,        uint id,        uint amount,        bytes memory data    ) public virtual override {
        require(            from == msg.sender || isApprovedForAll(from, msg.sender),            "ERC1155: caller is not owner nor approved"        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(        address from,        address to,        uint[] memory ids,        uint[] memory amounts,        bytes memory data    ) public virtual override {
        require(            from == msg.sender || isApprovedForAll(from, msg.sender),            "ERC1155: transfer caller is not owner nor approved"        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function _safeTransferFrom(     address from,        address to,        uint id,        uint amount,        bytes memory data    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        require(_owners[id] == from && amount < 2, "ERC1155: insufficient balance for transfer");
        if (amount == 1) {            _owners[id] = to;        }
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);

        userNftQuantities[from] -= amount;
        userNftQuantities[to]   += amount;
    }
    function _safeBatchTransferFrom(        address from,        address to,        uint[] memory ids,        uint[] memory amounts,        bytes memory data    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;

        for (uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];
            require(_owners[id] == from && amounts[i] < 2, "ERC1155: insufficient balance for transfer");
            if (amounts[i] == 1) 
            {
                _owners[id] = to;            

                userNftQuantities[from] -= amounts[i];
                userNftQuantities[to]   += amounts[i];
            }
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    function _setURI(string memory newuri) internal virtual {        _uri = newuri;    }
    function _mint(        address to,        uint id,        uint amount,        bytes memory data    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(amount < 2, "ERC1155D: exceeds supply");
        require(id < MAX_SUPPLY, "ERC1155D: invalid id");
        address operator = msg.sender;
        if (amount == 1) {            _owners[id] = to;        }
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);

        userNftQuantities[to]+=amount;
    }
    function _setApprovalForAll(        address owner,        address operator,        bool approved    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _doSafeTransferAcceptanceCheck(        address operator,        address from,        address to,        uint id,        uint amount,        bytes memory data    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {                revert(reason);            } catch {                revert("ERC1155: transfer to non ERC1155Receiver implementer");            }
        }
    }
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _prepayGas(uint start, uint end) internal {
        require(end <= MAX_SUPPLY, "ERC1155D: end id exceeds maximum");

        for (uint i = start; i < end; i++) {

            bytes32 slotValue;
            assembly {
                slotValue := sload(add(_owners.slot, i))
            }

            bytes32 leftmostBitSetToOne = slotValue | bytes32(uint(1) << 255);
            assembly {
                sstore(add(_owners.slot, i), leftmostBitSetToOne)
            }
        }
    }
    function getOwnershipRecordOffChain() external view returns(address[MAX_SUPPLY] memory) { return _owners;    }
    function ownerOf(uint id) external view returns(address) {
        require(id < _owners.length, "ERC1155D: id exceeds maximum");
        address owner = _owners[id];
        require(owner != address(0), "ERC1155D: owner query for nonexistent token");
        return owner;
    }

}
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

struct  TStat
{
    uint    reservedCount;
    uint    mintSalesCount;
    uint    mintWhitelistCount;
    uint    mintedTokenCount;
    uint    totalCount;
}

struct TAffiliate
{
    uint    mintCount;
    uint    nftCount;
    uint    totalAmount;
    uint    revenue;
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
contract    AMagicMandarsNft  is  ERC1155D
{
    using Address     for address;
    using Strings     for uint;
    using MerkleProof for bytes32[];
 
    string baseSVG = "<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='1024'>"; 

    string svgDEF1  = "<defs><linearGradient gradientTransform='rotate(150, 0.5, 0.5)' x1='50%' y1='0%' x2='50%' y2='100%' id='f3xG'><stop stop-color='";
	string svgDEF1b = "' stop-opacity='1' offset='0%'></stop><stop stop-color='";
    string svgDEF1c = "' stop-opacity='1' offset='100%'></stop></linearGradient>";

    string svgDEF2  = "<filter id='f3xF' x='-20%' y='-20%' width='140%' height='140%' filterUnits='objectBoundingBox' primitiveUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feTurbulence type='fractalNoise' baseFrequency='0.005 0.003' numOctaves='2' seed='2' stitchTiles='stitch' x='0%' y='0%' width='100%' height='100%' result='turbulence'/><feGaussianBlur stdDeviation='20 0' x='0%' y='0%' width='100%' height='100%' in='turbulence' edgeMode='duplicate' result='blur'/>";
  	
    string svgDEF3  = "<feBlend mode='";
    string svgDEF3b = "' x='0%' y='0%' width='100%' height='100%' in='SourceGraphic' in2='blur' result='blend'></feBlend></filter></defs><rect width='1024' height='1024' fill='url(#f3xG)' filter='url(#f3xF)'><animateTransform attributeName='transform' type='scale' begin='0s' dur='30s' values='1,1; ";
    
    string[8] svgCageForces = 
    [
        "1.5,1.2; 1,1;' repeatCount='indefinite'/></rect>",        "1.4,1.3; 1,1;' repeatCount='indefinite'/></rect>",        "1.3,1.3; 1,1;' repeatCount='indefinite'/></rect>",
        "1.0,1.4; 1,1;' repeatCount='indefinite'/></rect>",        "1.1,1.5; 1,1;' repeatCount='indefinite'/></rect>",        "1.2,1.3; 1,1;' repeatCount='indefinite'/></rect>",
        "1.0,1.5; 1,1;' repeatCount='indefinite'/></rect>",        "1.0,1.3; 1,1;' repeatCount='indefinite'/></rect>"
    ];

    string svgFX1   = "<animateTransform attributeType='xml' attributeName='transform' type='rotate' from='";
    string svgFX1b  = " 512 512' to='";
    string svgFX1c  = " 512 512' dur='";
    string svgFX1d  = "s' additive='sum' repeatCount='indefinite' />";
    
    //--------

    string[] blendFxs = [ "color-burn", "color-dodge" ];

            //------- TRAITS

    //string[] lineages = [ "Moonshaft", "RiverLorn", "DagFire", "Windale", "HagenPit", "Dorden" ];

    string[] cages    = [  "Mashke", "Greenuk",  "Burmog",  "Kimreek", "Arerion",   "Arkamia", "Fauln",  "Alpyen" ];
    string[] locks    = [ "Oldrend", "PasLight", "Halfen",  "Piltran", "Silverfor", "Fergun",  "Dozner", "Tholam" ];

            //------- NFT

    address             ownerWallet;

    string  public      name   = "OnChain Magic Mandars";
    string  public      symbol = "OCMM";

    uint[2]             whitelistPrices = [ 0.045 ether, 0.00001 ether ];
    uint[2]             salesPrices     = [ 0.060 ether, 0.00002 ether ];

    uint    constant    MAX_PER_WALLET      = 30;

    uint    constant    AUTHOR_PRE_PERCENT  = 8;            // Keep immediatly 8% of received crypto for the author. 
    
    uint                AUTHOR_MINT_PREAMOUNT       = 0;
    uint                AUTHOR_WHITELIST_PREAMOUNT  = 0;
    uint                USER_MINT_REFUNDAMOUNT      = 0;
    uint                USER_WHITELIST_REFUNDAMOUNT = 0;

    uint    constant    REFUND_TIME_END = 1690848000;   // Tuesday 1 August 2023 00:00:00 (gmt+0) 

    mapping(uint => uint)       private     nftRefundModes;        // 0=OFF  1=MINT  2=WHITELIST   3=REFUNDED
    mapping(uint => address)    private     nftMinters;

    uint public         MAX_RESERVE         = 300;
    uint public         MAX_MINT            = MAX_SUPPLY - MAX_RESERVE;
    uint public         maxMintable         = MAX_MINT;
    uint public         leftTokenCount      = MAX_SUPPLY;
    uint private        reservedCount       = 0;
    uint private        mintedTokenCount    = 0;
    uint private        mintSalesCount      = 0;
    uint private        mintWhitelistCount  = 0;
    uint private        generatedTokenCount = 0;

    mapping(address => uint)    mintedQuantities;
    
    //-------

    mapping(uint => uint8)      private     proposedHashes;      // used to avoid using the same hash on CreateLoan calls

    uint                        private     ecLimit = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
    string                      private     signHeader    = "\x19Ethereum Signed Message:\n32";

    address                     public      signingEntity;
    mapping(uint => bool)       private     registeredSigningEntities;

    uint                        private     affiliatePercentInM100 = 20 * 100;
    mapping(address=>TAffiliate)private     affiliatesStats;

            //-----

    uint    public      whitelistPrice;
    uint    public      salesPrice;

    uint    public      presalesDate = 1655700000;
    uint    public      salesDate    = 1655769600;
    uint    public      revealDate   = salesDate + (24*86400*4);        // 4 days after the salesDate

    bytes32     whitelistMerkleRoot;

            //-----

    mapping(uint => uint) public mandarHash;

    //-------

    constructor() ERC1155D("")
    {
        ownerWallet = msg.sender;

        if (block.chainid==1 || block.chainid==137)
        {
            salesPrice     = salesPrices[0];
            whitelistPrice = whitelistPrices[0];
        }
        else
        {
            salesPrice     = salesPrices[1];
            whitelistPrice = whitelistPrices[1];
        }
        
        AUTHOR_MINT_PREAMOUNT       = (salesPrice     * AUTHOR_PRE_PERCENT) /100;
        AUTHOR_WHITELIST_PREAMOUNT  = (whitelistPrice * AUTHOR_PRE_PERCENT) /100;
        USER_MINT_REFUNDAMOUNT      = salesPrice     - AUTHOR_MINT_PREAMOUNT;
        USER_WHITELIST_REFUNDAMOUNT = whitelistPrice - AUTHOR_WHITELIST_PREAMOUNT;
    }
    
    event   SetMintDates(uint newPresalesDate, uint newSalesDate);
    event   Withdraw(uint amount);
    event   PayAffiliateNftFees(address wallet, uint affiliateAmount, uint totalAmount, uint quantitySold, uint pricePerNft);
    event   SetMerkleRoot(bytes32 newMerkleRoot);
    event   SetSigningEntity(bool done);
    event   Refunded(uint tokenId, uint amountToSend);

    //=============================================================================
    function getUserNftQuantity(address guy) external view returns(uint)
    {
        return userNftQuantities[guy];
    }
    //=============================================================================
    function    uri(uint tokenId) public view virtual override returns (string memory) 
    {
        string memory       finalSVG;
        string memory       leaves;
        string memory       fx;
        uint                direction;
        uint                duration1;
        uint                duration2;
        uint                duration3;
        uint                nLeaf;
        uint                directionScore;

        if (block.chainid==137 || block.chainid==1)     // on Mainnet only
        {
            require(tokenId<=generatedTokenCount, "Id??");      // Voir uniquement les NFT deja mintés

            if (block.timestamp<revealDate)                 // We don't yet show the Mandars yet
            {
                return "https://";
            }
        }

        uint rndSeed  = tokenId * 0x1234;//3003;
        
        //-----

        uint idx = getRand(rndSeed) & 1023;   rndSeed++;

             if (idx>=750)      idx = 0;
        else if (idx>=550)      idx = 1;
        else if (idx>=400)      idx = 2;
        else if (idx>=300)      idx = 3;
        else if (idx>=210)      idx = 4;
        else if (idx>=130)      idx = 5;
        else if (idx>=50)       idx = 6;
        else                    idx = 7;

        //----- First Ring

        (fx, direction, duration1) = forgeFormAnimation(rndSeed+1);    rndSeed+=20;

            nLeaf = 5 + (getRand(rndSeed) & 3);//% 4;

                 if (nLeaf==5)  leaves = string(abi.encodePacked("<g id='r1'>", genLeaf5Angles(rndSeed,   rgbToSvgColor(getRand(rndSeed+1)),  rgbToSvgColor(getRand(rndSeed+2))),  fx,"</g>"));
            else if (nLeaf==6)  leaves = string(abi.encodePacked("<g id='r1'>", genLeaf6Angles(rndSeed+3, rgbToSvgColor(getRand(rndSeed+4)),  rgbToSvgColor(getRand(rndSeed+5))),  fx,"</g>"));
            else if (nLeaf==7)  leaves = string(abi.encodePacked("<g id='r1'>", genLeaf7Angles(rndSeed+5, rgbToSvgColor(getRand(rndSeed+7)),  rgbToSvgColor(getRand(rndSeed+8))),  fx,"</g>"));
            else                leaves = string(abi.encodePacked("<g id='r1'>", genLeaf8Angles(rndSeed+8, rgbToSvgColor(getRand(rndSeed+10)), rgbToSvgColor(getRand(rndSeed+11))), fx,"</g>"));
            
            rndSeed+=20;

            idx = getRand(rndSeed) & 1023;   rndSeed++;

                 if (idx>=750)      idx = 0;
            else if (idx>=550)      idx = 1;
            else if (idx>=400)      idx = 2;
            else if (idx>=300)      idx = 3;
            else if (idx>=210)      idx = 4;
            else if (idx>=130)      idx = 5;
            else if (idx>=50)       idx = 6;
            else                    idx = 7;

            string memory nftContent = string(abi.encodePacked("{\"name\":\"Mandar #", tokenId.toString(), "\",", 
                                        "\"attributes\":[{\"trait_type\":\"Cage\",\"value\":\"", cages[idx], 
                                        "\"},{\"trait_type\":\"Len1\",\"value\":\"",nLeaf.toString(), 
                                        "\"},{\"trait_type\":\"Rol1\",\"value\":\"",duration1.toString(), "\"},"));

            directionScore = direction;

        //----- Second Ring

        (fx, direction, duration2) = forgeFormAnimation(rndSeed+2);     if (duration2/10==duration1/10)  duration2/=2;//duration1+15;     
                
            rndSeed+=20;
            nLeaf = 5 + (getRand(rndSeed) & 3);//% 4;

                 if (nLeaf==5)  leaves = string(abi.encodePacked(leaves, "<g id='r2'>", genLeaf5Angles(rndSeed,   rgbToSvgColor(getRand(rndSeed+1)),  rgbToSvgColor(getRand(rndSeed+2))),  fx,"</g>"));
            else if (nLeaf==6)  leaves = string(abi.encodePacked(leaves, "<g id='r2'>", genLeaf6Angles(rndSeed+3, rgbToSvgColor(getRand(rndSeed+4)),  rgbToSvgColor(getRand(rndSeed+5))),  fx,"</g>"));
            else if (nLeaf==7)  leaves = string(abi.encodePacked(leaves, "<g id='r2'>", genLeaf7Angles(rndSeed+5, rgbToSvgColor(getRand(rndSeed+7)),  rgbToSvgColor(getRand(rndSeed+8))),  fx,"</g>"));
            else                leaves = string(abi.encodePacked(leaves, "<g id='r2'>", genLeaf8Angles(rndSeed+8, rgbToSvgColor(getRand(rndSeed+10)), rgbToSvgColor(getRand(rndSeed+11))), fx,"</g>"));
            
            rndSeed+=20;

            idx = getRand(rndSeed) & 1023;   rndSeed++;

                 if (idx>=500)      idx = 0;
            else if (idx>=250)      idx = 1;
            else if (idx>=100)      idx = 2;
            else if (idx>=35)       idx = 3;
            else                    idx = 4;

            nftContent = string(abi.encodePacked(nftContent,
                                                "{\"trait_type\":\"Len2\",\"value\":\"",nLeaf.toString(),
                                            "\"},{\"trait_type\":\"Rol2\",\"value\":\"",duration2.toString(), "\"},"));

            directionScore += direction << 1;

        //----- Third Ring

        (fx, direction, duration3) = forgeFormAnimation(rndSeed+3);     if (duration3/10==duration1/10)   duration3/=2;//duration1+25;
                                                                        if (duration3/10==duration2/10)   duration3/=2;//duration2+13;
            rndSeed+=20;
            nLeaf = 5 + (getRand(rndSeed) & 3);//% 4;

                 if (nLeaf==5)  leaves = string(abi.encodePacked(leaves, "<g id='r3'>", genLeaf5Angles(rndSeed,   rgbToSvgColor(getRand(rndSeed+1)),  rgbToSvgColor(getRand(rndSeed+2))),  fx,"</g>"));
            else if (nLeaf==6)  leaves = string(abi.encodePacked(leaves, "<g id='r3'>", genLeaf6Angles(rndSeed+3, rgbToSvgColor(getRand(rndSeed+4)),  rgbToSvgColor(getRand(rndSeed+5))),  fx,"</g>"));
            else if (nLeaf==7)  leaves = string(abi.encodePacked(leaves, "<g id='r3'>", genLeaf7Angles(rndSeed+5, rgbToSvgColor(getRand(rndSeed+7)),  rgbToSvgColor(getRand(rndSeed+8))),  fx,"</g>"));
            else                leaves = string(abi.encodePacked(leaves, "<g id='r3'>", genLeaf8Angles(rndSeed+8, rgbToSvgColor(getRand(rndSeed+10)), rgbToSvgColor(getRand(rndSeed+11))), fx,"</g>"));

            rndSeed+=20;

            directionScore += direction << 2;

        //-----

        idx = getRand(rndSeed);   rndSeed++;

        nftContent = string(abi.encodePacked(nftContent,
                                            "{\"trait_type\":\"Len3\",\"value\":\"",nLeaf.toString(),
                                        "\"},{\"trait_type\":\"Rol3\",\"value\":\"",duration3.toString(), 
                                        "\"},{\"trait_type\":\"Lock\",\"value\":\"",locks[directionScore]
                                        ));

        nLeaf = getRand(rndSeed*11) & 1023;    rndSeed++;          //nLeaf = getRand(rndSeed) & 1023;   rndSeed++;

                 if (nLeaf>=750)    nLeaf = 900;
            else if (nLeaf>=550)    nLeaf = 1100;
            else if (nLeaf>=400)    nLeaf = 1400;
            else if (nLeaf>=300)    nLeaf = 1800;
            else if (nLeaf>=210)    nLeaf = 2300;
            else if (nLeaf>=130)    nLeaf = 2900;
            else if (nLeaf>=50)     nLeaf = 3600;
            else                    nLeaf = 5000;

        nftContent = string(abi.encodePacked(nftContent,
                                        "\"},{\"trait_type\":\"Complexity\",\"value\":\"",(30+(idx%70)).toString(),
                                        "0\"},{\"trait_type\":\"Energy\",\"value\":\"",nLeaf.toString(),      //((16+(nLeaf%185))*10).toString(),
                                        "\"}"));

        //-----

        /*uint darkMode*/idx   = ((getRand(rndSeed+5) & 127) > 64) ? 1:0;  rndSeed++;

        finalSVG = string(abi.encodePacked(baseSVG, svgDEF1, rgbToSvgColor(getRand(rndSeed+6)), svgDEF1b, rgbToSvgColor(getRand(rndSeed+7))));
        finalSVG = string(abi.encodePacked(finalSVG, svgDEF1c, svgDEF2, svgDEF3, blendFxs[/*darkMode*/idx], svgDEF3b, svgCageForces[rndSeed&7]));
        finalSVG = string(abi.encodePacked(finalSVG, leaves, "</svg>"));
        finalSVG = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(finalSVG))));

        nftContent = string(abi.encodePacked(nftContent,"],\"image\":\"", finalSVG, "\"}"));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(nftContent))));
    }
    //--------------------------------------------------------------------------------------
    function    genLeaf8Angles(uint rndSeed, string memory col1, string memory col2) internal pure returns(string memory)
    {
        string memory leaves;
        
        uint d1 = getRand(rndSeed)   % 448;   
        uint d2 = getRand(rndSeed+1) % 448;   
        uint d3 = getRand(rndSeed+2) % 448;   
        uint d4 = getRand(rndSeed+3) % 448;

        leaves = string(abi.encodePacked("<g fill='", col1, "'>", 
                        calcLeafAB(d1,d2,d3,d4,   16384,      0,  15137,   6270),
                        calcLeafAB(d1,d2,d3,d4,   11583,  11583,   6270,  15137),
                        calcLeafAB(d1,d2,d3,d4,       0,  16384,  -6271,  15137),
                        calcLeafAB(d1,d2,d3,d4,  -11586,  11583, -15138,   6270),
                        calcLeafAB(d1,d2,d3,d4,  -16384,      0, -15138,  -6271),
                        calcLeafAB(d1,d2,d3,d4,  -11586, -11586,  -6271, -15138),
                        calcLeafAB(d1,d2,d3,d4,       0, -16384,   6270, -15138)));
                        
        leaves = string(abi.encodePacked(leaves,
                        calcLeafAB(d1,d2,d3,d4,   11583, -11586,  15137,  -6271),"</g><g fill='",col2,"'>",
                        calcLeafBA(d1,d2,d3,d4,   11583,  11583,  15137,   6270),
                        calcLeafBA(d1,d2,d3,d4,       0,  16384,   6270,  15137),
                        calcLeafBA(d1,d2,d3,d4,  -11586,  11583,  -6271,  15137),
                        calcLeafBA(d1,d2,d3,d4,  -16384,      0, -15138,   6270),
                        calcLeafBA(d1,d2,d3,d4,  -11586, -11586, -15138,  -6271)));

        leaves = string(abi.encodePacked(leaves,
                        calcLeafBA(d1,d2,d3,d4,      0, -16384, -6271, -15138),
                        calcLeafBA(d1,d2,d3,d4,  11583, -11586,  6270, -15138),
                        calcLeafBA(d1,d2,d3,d4,  16384,      0, 15137,  -6271),
                            "</g>"));
        return leaves;
    }
    //--------------------------------------------------------------------------------------
    function    genLeaf7Angles(uint rndSeed, string memory col1, string memory col2) internal pure returns(string memory)
    {
        string memory leaves;
        
        uint d1 = getRand(rndSeed)   % 448;   
        uint d2 = getRand(rndSeed+1) % 448;   
        uint d3 = getRand(rndSeed+2) % 448;   
        uint d4 = getRand(rndSeed+3) % 448;

        leaves = string(abi.encodePacked("<g fill='", col1, "'>",
                        calcLeafAB(d1,d2,d3,d4,   16384,      0,  14761,   7109),
                        calcLeafAB(d1,d2,d3,d4,   10215,  12809,   3645,  15972),
                        calcLeafAB(d1,d2,d3,d4,   -3646,  15972, -10216,  12809),
                        calcLeafAB(d1,d2,d3,d4,  -14762,   7109, -16384,      0),
                        calcLeafAB(d1,d2,d3,d4,  -14762,  -7110, -10216, -12810),
                        calcLeafAB(d1,d2,d3,d4,   -3646, -15973,   3645, -15973),
                        calcLeafAB(d1,d2,d3,d4,   10215, -12810,  14761,  -7110),
                            "</g>"
                            ));

        leaves = string(abi.encodePacked(leaves, "<g fill='", col2, "'>", 
                        calcLeafBA(d1,d2,d3,d4,   14761,  7109,  10215, 12809),
                        calcLeafBA(d1,d2,d3,d4,    3645, 15972,  -3646, 15972),
                        calcLeafBA(d1,d2,d3,d4,  -10216, 12809, -14762,  7109),
                        calcLeafBA(d1,d2,d3,d4,  -16384,     0, -14762, -7110),
                        calcLeafBA(d1,d2,d3,d4,  -10216,-12810,  -3646,-15973),
                        calcLeafBA(d1,d2,d3,d4,    3645,-15973,  10215,-12810),
                        calcLeafBA(d1,d2,d3,d4,   14761, -7110,  16384,     0),
                            "</g>"
                            ));

        return leaves;
    }
    //--------------------------------------------------------------------------------------
    function    genLeaf6Angles(uint rndSeed, string memory col1, string memory col2) internal pure returns(string memory)
    {
        string memory leaves;
        
        uint d1 = getRand(rndSeed)   % 448;   
        uint d2 = getRand(rndSeed+1) % 448;   
        uint d3 = getRand(rndSeed+2) % 448;   
        uint d4 = getRand(rndSeed+3) % 448;

        leaves = string(abi.encodePacked("<g fill='", col1, "'>", 
                        calcLeafAB(d1,d2,d3,d4,   16384,      0,  14188,   8192),
                        calcLeafAB(d1,d2,d3,d4,    8192,  14188,      0,  16384),
                        calcLeafAB(d1,d2,d3,d4,   -8192,  14188, -14189,   8192),
                        calcLeafAB(d1,d2,d3,d4,  -16384,      0, -14189,  -8192),
                        calcLeafAB(d1,d2,d3,d4,   -8192, -14189,      0, -16384),
                        calcLeafAB(d1,d2,d3,d4,    8192, -14189,  14188,  -8192),
                            "</g>"));

        leaves = string(abi.encodePacked(leaves, "<g fill='", col2, "'>",
                        calcLeafBA(d1,d2,d3,d4,    8192,  14188,  14188,  8192),
                        calcLeafBA(d1,d2,d3,d4,   -8192,  14188,      0, 16384),
                        calcLeafBA(d1,d2,d3,d4,  -16384,      0, -14189,  8192),
                        calcLeafBA(d1,d2,d3,d4,   -8192, -14189, -14189, -8192),
                        calcLeafBA(d1,d2,d3,d4,    8192, -14189,      0,-16384),
                        calcLeafBA(d1,d2,d3,d4,   16384,      0,  14188, -8192),
                            "</g>"));

        return leaves;
    }
    //--------------------------------------------------------------------------------------
    function    genLeaf5Angles(uint rndSeed, string memory col1, string memory col2) internal pure returns(string memory)
    {
        string memory leaves;
        
        uint d1 = getRand(rndSeed)   % 448;   
        uint d2 = getRand(rndSeed+1) % 448;   
        uint d3 = getRand(rndSeed+2) % 448;   
        uint d4 = getRand(rndSeed+3) % 448;

        leaves = string(abi.encodePacked("<g fill='", col1, "'>", 
                        calcLeafAB(d1,d2,d3,d4,   16384,     0,  13254,   9630),
                        calcLeafAB(d1,d2,d3,d4,    5062, 15582,  -5063,  15582),
                        calcLeafAB(d1,d2,d3,d4,  -13257,  9630, -16384,      0),
                        calcLeafAB(d1,d2,d3,d4,  -13257, -9631,  -5063, -15583),
                        calcLeafAB(d1,d2,d3,d4,    5062,-15583,  13254,  -9631),
                            "</g>"));

        leaves = string(abi.encodePacked(leaves, "<g fill='", col2, "'>",
                        calcLeafBA(d1,d2,d3,d4,    5062,  15582,  13254,   9630),
                        calcLeafBA(d1,d2,d3,d4,  -13257,   9630,  -5063,  15582),
                        calcLeafBA(d1,d2,d3,d4,  -13257,  -9631, -16384,      0),
                        calcLeafBA(d1,d2,d3,d4,    5062, -15583,  -5063, -15583),
                        calcLeafBA(d1,d2,d3,d4,   16384,      0,  13254,  -9631),
                            "</g>"));
        return leaves;
    }
    //--------------------------------------------------------------------------------------
    function    calcLeafAB(uint d1,  uint d2,  uint d3,   uint d4, 
                           int cosA, int sinA, int cosAB, int sinAB)
                                internal pure returns(string memory)
    {
        uint ax  = uint(512 + ((int(d1)*cosA)>>14));        
        uint ay  = uint(512 + ((int(d1)*sinA)>>14));
        uint ax2 = uint(512 + ((int(d2)*cosA)>>14));        
        uint ay2 = uint(512 + ((int(d2)*sinA)>>14));

        string memory leaf = string(abi.encodePacked("<path d='M", ax.toString(),",", ay.toString(), "C", ax2.toString(),",", ay2.toString(), " "));

        ax  = uint(512 + ((int(d3)*cosAB)>>14));        
        ay  = uint(512 + ((int(d3)*sinAB)>>14));
        ax2 = uint(512 + ((int(d4)*cosAB)>>14));        
        ay2 = uint(512 + ((int(d4)*sinAB)>>14));

        return string(abi.encodePacked(leaf, ax.toString(),",", ay.toString(), " ", ax2.toString(),",",ay2.toString(), "Z'/>"));
    }
    //--------------------------------------------------------------------------------------
    function    calcLeafBA(uint d1,  uint d2,  uint d3,   uint d4, 
                                int cosA, int sinA, int cosAB, int sinAB)
                                    internal pure returns(string memory)
    {
        uint ax  = uint(512 + ((int(d1)*cosAB)>>14));        
        uint ay  = uint(512 + ((int(d1)*sinAB)>>14));
        uint ax2 = uint(512 + ((int(d2)*cosAB)>>14));        
        uint ay2 = uint(512 + ((int(d2)*sinAB)>>14));

        string memory leaf = string(abi.encodePacked("<path d='M", ax.toString(),",", ay.toString(), "C", ax2.toString(),",", ay2.toString(), " "));

        ax  = uint(512 + ((int(d3)*cosA)>>14));        
        ay  = uint(512 + ((int(d3)*sinA)>>14));
        ax2 = uint(512 + ((int(d4)*cosA)>>14));        
        ay2 = uint(512 + ((int(d4)*sinA)>>14));

        return string(abi.encodePacked(leaf, ax.toString(),",", ay.toString(), " ", ax2.toString(),",",ay2.toString(), "Z'/>"));
    }
    //--------------------------------------------------------------------------------------
    function    getRand(uint seed) internal pure returns(uint)
    {
        return uint(keccak256(abi.encodePacked(seed)));
    }
    //--------------------------------------------------------------------------------------
    function    forgeFormAnimation(uint rndSeed) internal pure returns(string memory, uint rotateMode, uint duration)
    {
        string memory fx;

        rotateMode = getRand(rndSeed)&1;                        rndSeed++;
        duration   = (400 + ((getRand(rndSeed)%50)*20)) / 15;   rndSeed++;

        if (rotateMode==0)
        {
            fx = string(abi.encodePacked("<animateTransform attributeType='xml' attributeName='transform' type='rotate' from='360 512 512' to='0 512 512' dur='", 
                                   duration.toString(),  
                                   "s' additive='sum' repeatCount='indefinite'/>"));
        }
        else
        {
            fx = string(abi.encodePacked("<animateTransform attributeType='xml' attributeName='transform' type='rotate' from='0 512 512' to='360 512 512' dur='", 
                                   duration.toString(),  
                                   "s' additive='sum' repeatCount='indefinite'/>"));
        }

        return (fx, rotateMode, duration);
    }
    //--------------------------------------------------------------------------------------
    function    rgbToSvgColor(uint rgb) internal pure returns(string memory)
    {
        return string(abi.encodePacked("rgb(", ((rgb>>16)&255).toString(), ',', ((rgb>>8)&255).toString(), ',', (rgb&255).toString(), ')'));
    }
    //--------------------------------------------------------------------------------------
    function    setOwnerWallet(address newAddress) external onlyOwner
    {
        ownerWallet = newAddress;
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    reserve(uint quantity) external onlyOwner
    {
        require(leftTokenCount >= quantity,            "E1");   //Non left");
        require(reservedCount+quantity <= MAX_RESERVE, "E2");   //All reserved");

        reservedCount  += quantity;
        leftTokenCount -= quantity;

        for (uint i=0; i<quantity; i++)
        {
            generatedTokenCount++;
           
            _mint(msg.sender, generatedTokenCount, 1,'');

            nftRefundModes[generatedTokenCount] = 0;    // Author NFTs are not refundable
            nftMinters[generatedTokenCount]     = msg.sender;
        }
    }
    //=============================================================================
    function    mint(uint quantity) external payable
    {
        uint qty = mintedQuantities[msg.sender] + quantity;

        require(qty<=MAX_PER_WALLET,                    "Dec qty");

        //require(msg.value==quantity*salesPrice,         "Bad amount");
        require(quantity!=0,                            "Quantity=0");
        require(leftTokenCount >= quantity,             "0 left");
        require(block.timestamp>=salesDate,             "Closed");
        require(mintedTokenCount+quantity<=MAX_MINT,    "Not enough left");

        //-----²
        
        leftTokenCount               -= quantity;
        mintedQuantities[msg.sender] += quantity;
        mintedTokenCount             += quantity;
        mintSalesCount               += quantity;

        for (uint i=0; i < quantity; i++)
        {
            generatedTokenCount++;
            
            _mint(msg.sender, generatedTokenCount, 1, '');

            nftRefundModes[generatedTokenCount] = 1;       // Tag this NFT to be refundable for now
            nftMinters[generatedTokenCount]     = msg.sender;
        }

        manageReceivedAmount(quantity, true);
        //payAffiliateNftFees(affWallet, msg.value, quantity, salesPrice);     // Manage to pay an affiliate or not
    }
    //=============================================================================
    function    whitelistMint(uint      quantity, 
                              //address   affWallet, 
                              bytes32[] calldata merkleProof) 
                    external payable
    {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");

        //-----

        uint qty = mintedQuantities[msg.sender] + quantity;

        require(qty<=MAX_PER_WALLET,                    "Dec qty");

        require(msg.value==quantity*whitelistPrice,     "Bad amount");
        require(quantity!=0,                            "Quantity=0");
        require(leftTokenCount >= quantity,             "0 left");
        require(block.timestamp>=salesDate,             "Closed");
        require(mintedTokenCount+quantity<=MAX_MINT,    "Not enough left");

        //-----
        
        leftTokenCount               -= quantity;
        mintedQuantities[msg.sender] += quantity;
        mintedTokenCount             += quantity;
        mintSalesCount               += quantity;

        for (uint i=0; i < quantity; i++)
        {
            generatedTokenCount++;
            
            _mint(msg.sender, generatedTokenCount, 1, '');

            nftRefundModes[generatedTokenCount] = 2;       // Tag this NFT to be refundable for now
            nftMinters[generatedTokenCount]     = msg.sender;
        }

        manageReceivedAmount(quantity, true);
        //payAffiliateNftFees(affWallet, msg.value, quantity, whitelistPrice);    // Manage to pay an affiliate or not
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    withdraw() external onlyOwner
    {
        require(block.timestamp > REFUND_TIME_END, "Author cannot withdraw for now");       // Grace period not finised yet

        uint balance = address(this).balance;

        (bool sent,) = ownerWallet.call{value: balance}("");    require(sent, "Failed");    // payable(ownerWallet).transfer(balance);

        emit Withdraw(balance);
    }
    //=============================================================================
    function    manageReceivedAmount(uint qty, bool isFromMint) internal
    {
                        uint amountToSend  = AUTHOR_WHITELIST_PREAMOUNT;
        if (isFromMint)      amountToSend  = AUTHOR_MINT_PREAMOUNT;
                             amountToSend *= qty;
        
        (bool sent,) = ownerWallet.call{value: amountToSend}("");    require(sent, "Auth pre amount Failed");    // Send 8% of the transaction to author's wallet
    }
    //=============================================================================
    function    refund(uint tokenId) external
    {
        require(nftRefundModes[tokenId]!=0,      "Not refundable");
        require(nftRefundModes[tokenId]!=3,      "Already refunded");
        require(nftMinters[tokenId]==msg.sender, "You are not the Minter");

                                        uint amountToSend  = USER_MINT_REFUNDAMOUNT;
        if (nftRefundModes[tokenId]==2)      amountToSend  = USER_WHITELIST_REFUNDAMOUNT;

        nftRefundModes[tokenId] = 3;            // SET AS REFUNDED!!!

        safeTransferFrom(msg.sender, ownerWallet, tokenId, 1,"");       // This NFT unfortunatly returns to the NFT author

        (bool sent,) = nftMinters[tokenId].call{value: amountToSend}("");    require(sent, "Refund Failed");    // Send 8% of the transaction to author's wallet

        emit Refunded(tokenId, amountToSend);
    }
    //=============================================================================
    //=============================================================================
    function    getMintPeriod() public view returns(uint period)
    {
             if (block.timestamp>=salesDate)        return 2;       // PUBLIC SALES
        else if (block.timestamp>=presalesDate)     return 1;       // PRE-SALES
                                                    return 0;       // OFF
    }
    //=============================================================================
    function    getStats() external view returns(TStat memory)
    {
        TStat memory stat = TStat
        (
            reservedCount,
            mintSalesCount,
            mintWhitelistCount,
            mintedTokenCount,
            generatedTokenCount
        );

        return stat;
    }
    //=============================================================================
    function    getWhitelistPrice() external view returns(uint price)
    {
        return whitelistPrice;
    }
    //=============================================================================
    function    getSalesPrice() external view returns(uint price)
    {
        return salesPrice;
    }
    //=============================================================================
    function    getCurrentPrice() external view returns(uint price)
    {
        uint mode = getMintPeriod();

                        uint currentPrice = salesPrice;
        if (mode==1)         currentPrice = whitelistPrice;
        
        return currentPrice;
    }
    //=============================================================================
    function    getDates() external view returns(uint,uint)
    {
        return (presalesDate, salesDate);
    }
    //=============================================================================
    //=============================================================================
    function    getMintedCount() public view returns(uint leftCount)
    {
        return mintedTokenCount;
    }
    //---------------------------------------------------------------------------
    function    getMintLeft() public view returns(uint leftCount)
    {
        return maxMintable - mintedTokenCount;
    }
    //---------------------------------------------------------------------------
    function    getMaxMintableCount() public view returns(uint leftCount)
    {
        return maxMintable;
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    setMintDates(uint newPresalesDate, uint newSalesDate) external onlyOwner
    {
        presalesDate = newPresalesDate;
        salesDate    = newSalesDate;

        emit SetMintDates(newPresalesDate, newSalesDate);
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    setMerkleRoot(bytes32 newRoot)   external onlyOwner
    {
        whitelistMerkleRoot = newRoot;

        emit SetMerkleRoot(newRoot);
    }
}