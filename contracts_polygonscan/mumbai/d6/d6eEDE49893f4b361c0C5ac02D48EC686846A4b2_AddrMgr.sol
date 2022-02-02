/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
interface IAuthLib { function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool); }
contract AddrMgr {
    bytes32 constant internal SMName = "AddrMgr";
    mapping(bytes32 => Row) internal AddrDB;
    bytes32[] internal DBKeys;
    struct Row {
        address ContractAddress;    //Contract Address
        address owner;              //Address of Modifier Wallet
        uint256 timestamp;          //Last Update
    }
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    modifier modcanDo(bytes32 FuncName) {
        require(_canDo(SMName, FuncName, msg.sender), "Not Authorized.");
        _;
    }
    function get(bytes32 ContractName) public view returns (address) {
        // If the value was never set, it will return the default value.
        address PANICAuthMgr = 0xd26585c65bFc725112d5d1177F3C3F02C70211A3;  //ToDo: Impostare l'indirizzo di un AuthMgr con Address e Permessi su indirizzi Base Speciali
        if(ContractName == "PANICAuthMgr") {return PANICAuthMgr; }  //In Caso vada in Errore l'AuthMagr Attuale
        address res = AddrDB[ContractName].ContractAddress;
        if(ContractName == "AuthMgr" && res == address(0)) {return PANICAuthMgr; }  //In Caso si perda l'Address del AuthMgr
        return res;
    }
    function set(bytes32 ContractName, address ContractAddress) external virtual modcanDo("set") {
        if(ContractName == "PANICAuthMgr") { revert("'PANICAuthMgr' address is Immutable!"); }
        if(AddrDB[ContractName].ContractAddress == address(0)) {
            DBKeys.push(ContractName);
        }
        AddrDB[ContractName] = Row(ContractAddress, msg.sender, block.timestamp);
        emit SecurityLog(SMName, "set", block.timestamp, msg.sender);
    }
    function Remove(bytes32 ContractName) external virtual modcanDo("Remove") {
        if(DBKeys.length > 1) {
            uint Ix = DBKeys.length;
            for(uint i = 0; i < DBKeys.length; i++) {
                if(DBKeys[i] == ContractName) { Ix = i; break; }
            }
            if(Ix == DBKeys.length) { return; }
            DBKeys[Ix] = DBKeys[DBKeys.length - 1];
            DBKeys.pop();
        }
        if(DBKeys.length == 1 && DBKeys[0] == ContractName) { DBKeys = new bytes32[](0); }
        delete AddrDB[ContractName];    // Reset the value to the default value.
        emit SecurityLog(SMName, "Remove", block.timestamp, msg.sender);
    }
    function List() external view virtual modcanDo("List") returns (bytes32[] memory) { return DBKeys; }
    function Length() external view returns(uint) { return DBKeys.length; }
    function Clear() external virtual modcanDo("Clear") returns (bool Res){
        for(uint i = 0; i < DBKeys.length; i++) { delete AddrDB[DBKeys[i]]; }
        DBKeys = new bytes32[](0);
        emit SecurityLog(SMName, "Clear", block.timestamp, msg.sender);
        return true;
    }
    function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool) { return _canDo(ContractName, FuncName, Sender); }
    function _canDo(bytes32 ContractName, bytes32 FuncName, address Sender) internal view returns (bool) {
        try IAuthLib(get("AuthMgr")).canDo(ContractName, FuncName, Sender) returns (bool res) { return res; }
        catch {
            try IAuthLib(get("PANICAuthMgr")).canDo(SMName, FuncName, msg.sender) returns (bool res) { return res; }
            catch { return true; }  //Se sia AuthMgr che PANICAuthMgr vanno in Errore autorizo la modifica per permettere che non si rompa TUTTO !!!
        }
    }
}

//[Funzioni Utente x ShibaWorldsMgr.sol]
//get
//canDo