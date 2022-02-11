// SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
import "SWImport.sol";
library SWUtils {
    address constant internal NFTWalletAddr = 0x26156da0BAa2fc52099f36042a6CDD95FA632848;   //JG75(1)   //ToDo: Inserire l'Indirizzo per Gestire gli NFT degli Utenti
    address constant internal Addr = 0xd6eEDE49893f4b361c0C5ac02D48EC686846A4b2;
    bytes32 constant internal SMCard = "CardMgr";
    bytes32 constant internal SMCardDes = "CardDesMgr";
    bytes32  constant internal SMStaking = "StakingMgr";
    bytes32 constant internal SMLand = "LandMgr";
    bytes32 constant internal SMMarket = "NFTMarket";
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    function LogSecurity(bytes32 SCMgr, bytes32 Action, address sender) external { emit SecurityLog(SCMgr, Action, block.timestamp, sender); }
    function IgetAddr(bytes32 AddrName) external view returns (address) { return _getAddr(AddrName); }
    function _getAddr(bytes32 AddrName) internal view returns (address) {
        address resAddr = IAddr(Addr).get(AddrName);
        require(resAddr != address(0), string(bytes.concat(AddrName, " Not Found!")));
        return resAddr;
    }
    // function CardAddr() external view returns (address) { return _getAddr(SMCard); }        //ToDo: chk if Needed
    // function CardDesAddr() external view returns (address) { return _getAddr(SMCardDes); }  //ToDo: chk if Needed
    // function StakingAddr() external view returns (address) { return _getAddr(SMStaking); }  //ToDo: chk if Needed
    // function LandAddr() external view returns (address) { return _getAddr(SMLand); }        //ToDo: chk if Needed
    // function MarketAddr() external view returns (address) { return _getAddr(SMMarket); }    //ToDo: chk if Needed
    //function CardAddr3() external view returns (address) { return _getAddr(SMCard); }
    function IcanDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool) { return IAddr(Addr).canDo(ContractName, FuncName, Sender); }
    function IgetCard(uint24 _cUID) external view returns (card memory) { return ICard(_getAddr(SMCard)).getCard(_cUID); }
    function IgetCard(uint8 Epoch, uint8 Collection, uint16 CardId) external view returns (card memory) { return ICard(_getAddr(SMCard)).getCard(Epoch, Collection, CardId); }
    function IchkCardReq(card memory L, card memory B) external view returns (bool) { return ICardDes(_getAddr(SMCardDes)).chkCardReq(L, B); }
    function IgetMarketItem(uint256 ItemId) external view returns (MarketItem memory) { return INFTMarket(_getAddr(SMMarket)).fetchItem(ItemId); }
    function IaddStake(address userAddr, uint96 coin) external returns (bool) { return IStaking(_getAddr(SMStaking)).addStake(userAddr, coin); }
    function IsubStake(address userAddr, uint96 coin) external returns (bool) { return IStaking(_getAddr(SMStaking)).subStake(userAddr, coin); }
    function IgetUserStake(address userAddr) external view returns (userStakes memory) { return IStaking(_getAddr(SMStaking)).getUserStake(userAddr); }

    function UID(uint8 Epoch, uint8 Collection, uint16 CardId, uint8 Level) external pure returns (uint24) {      //ToDo: Untested
        return (Epoch * 1000000) + (Collection * 10000) + (CardId * 10) + Level;
    }
    function UID(uint24 uid) public pure returns (cUID memory CardUID) {  //ToDo: Untested
        CardUID.Epoch = uint8(uid / 1000000);
        uid -= CardUID.Epoch * 1000000;
        CardUID.Collection = uint8(uid / 10000);
        uid -= CardUID.Collection * 10000;
        CardUID.CardId = uint16(uid / 10);
        uid -= CardUID.Collection * 10000;
        CardUID.Level = uint8(uid);
        return CardUID;
    }
    function getLevel(uint96 coin) external pure returns (uint8) {
        if(coin >= 10) { return 10; }
        else if(coin >= 9) { return 9; }
        else if(coin >= 9) { return 8; }
        else if(coin >= 7) { return 7; }
        else if(coin >= 6) { return 6; }
        else if(coin >= 5) { return 5; }
        else if(coin >= 4) { return 4; }
        else if(coin >= 3) { return 3; }
        else if(coin >= 2) { return 2; }
        else if(coin >= 1) { return 1; }
        else { return 0; } //coin >= 0
    }
    function toStr(uint256 value) external pure returns (string memory) {
        if (value == 0) { return "0"; }
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
    function toStr(bytes32 _bytes32) external pure returns (string memory) {
        return string(bytes.concat(_bytes32));
        // bytes memory bytesArray = new bytes(32);
        // for (uint256 i; i < 32; i++) { bytesArray[i] = _bytes32[i]; }
        // return string(bytesArray);
    }
    function toTrim(string memory str) external pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory res = new bytes(strBytes.length);
        uint i1 = 0;
        bool firstChar;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " " && !firstChar) { firstChar = true; }
            if(firstChar || strBytes[i2] != " ") {
                res[i1] = strBytes[i2];
                i1++;
            }
        }

        for(uint i4 = i1; i4 >= 0 ; i4--) {
            if(res[i4] != " ") { break; }
            i1--;
        }
        bytes memory res2 = new bytes(i1);
        for(uint i3 = 0; i3 < i1; i3++) { res2[i3] = res[i3]; }
        return string(res2);
    }
    function toTrimNew(string memory str) external pure returns (string memory) {    //ToDo: Untested
        bytes memory strBytes = bytes(str);
        uint i1 = 0;
        uint Char1Ix = 0;
        bool firstChar;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " " && !firstChar) {
                Char1Ix = i2;
                firstChar = true;
            }
            if(firstChar || strBytes[i2] != " ") { i1++; }
        }
        uint i4;
        for(i4 = (strBytes.length -1); i4 >= 0 ; i4--) {
            if(strBytes[i4] != " ") { break; }
            i1--;
        }
        i1 -= ((strBytes.length -1) - i4);
        bytes memory res2 = new bytes(i1);
        for(uint i3 = Char1Ix; i3 < (Char1Ix + i1); i3++) { res2[(i3 - Char1Ix)] = strBytes[i3]; }
        return string(res2);
    }
    function toTrimMiddle(string memory str) external pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory res = new bytes(strBytes.length);
        uint i1 = 0;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " ") {
                res[i1] = strBytes[i2];
                i1++;
            }
        }
        bytes memory res2 = new bytes(i1);
        for(uint i3 = 0; i3 < i1; i3++) { res2[i3] = res[i3]; }
        return string(res2);
    }
    function SubStr(string memory str, uint begin, uint end) external pure returns (string memory) {
        bytes memory tmp = bytes(str);
        if(end > tmp.length) { end = (tmp.length); }
        if(begin > end || begin >= tmp.length) { return ""; }
        uint L = end - begin;
        bytes memory a = new bytes(L);
        for(uint i = 0; i < L; i++) { a[i] = tmp[i+begin]; }
        return string(a);
    }
    function toUint(address addr) external pure returns (uint) { return uint256(uint160(addr)); }
    function toUint(bytes memory _bytes) external pure returns (uint) { return  uint(bytes32(_bytes)); }
    function toAddress(uint x) external pure returns (address) { return _toAddress(_toBytes(x, 32)); }
    function toAddress(bytes memory _bytes) external pure returns (address) { return _toAddress(_bytes); }
    function _toAddress(bytes memory _bytes) internal pure returns (address addr) { assembly { addr := mload(add(_bytes, 32)) }  }
    function toBytes(uint x) external pure returns (bytes memory b) { return _toBytes(x, 32); }
    function toBytes32(string memory txt) external pure returns (bytes32 b) { return bytes32(bytes(txt)); } //ToDo: Untested
    function _toBytes(uint x, uint s) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, s), x) }
    }
    function toBytes20(address addr) external pure returns (bytes20) { return bytes20(addr); }
    function Concat(string memory a, string memory b) external pure returns (string memory) { return string(bytes.concat(bytes(a), bytes(b))); }
    function indexOf(string memory Text, string memory SearchVal, bool CaseSensitive) public pure returns (int)  //Zero Based and CASE SENSITIVE
    {
        if(!CaseSensitive) {
            Text = _toLower(Text);
            SearchVal = _toLower(SearchVal);
        }
    	bytes memory h = bytes(Text);
    	bytes memory n = bytes(SearchVal);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length))  { return -1; }
    	if(h.length > (2**128 -1)) { return -1; }   //since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
        uint subindex = 0;
        for (uint i = 0; i < h.length; i ++)
        {
            if (h[i] == n[0]) // found the first char of b
            {
                subindex = 1;
                while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) { subindex++; }   // search until the chars don't match or until we reach the end of a or b
                if(subindex == n.length) { return int(i);} 
            }
        }
        return -1;
    }
    function toLower(string memory str) external pure returns (string memory) { return _toLower(str); }
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) { // Uppercase character...
                bStr[i] = bytes1(uint8(bStr[i]) + 32);  // So we add 32 to make it lowercase
            }
        }
        return string(bStr);
    }
    function isEqual(string memory strA, string memory strB) external pure returns (bool) { return  (keccak256(bytes(strA)) == keccak256(bytes(strB))); }   //Miglior Comparazione String. Anche Storage vs Memory -> keccak256(bytes(strA)) == keccak256(bytes(strB))
}
//Da Testo a bytes32 ? => bytes32 B = bytes32(bytes("prova"));
//trim
//isEqual