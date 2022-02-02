/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

//SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
contract AuthMgr {
    bytes32 constant internal SMName = "AuthMgr";
    address[] internal Auths = new address[](0);
    mapping(address => bool) private AuthsMap;
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    modifier modcanDo(bytes32 FuncName) {
        require(_canDo(SMName, FuncName, msg.sender), "Not Authorized.");
        _;
    }
    function List() external view virtual modcanDo("List") returns (address[] memory) { return Auths; }
    function Length() external view virtual modcanDo("Length") returns(uint) { return Auths.length; }
    function Clear() external virtual modcanDo("Clear") returns (bool Res) {
        Auths = new address[](0);
        for(uint i = 0; i < Auths.length; i++) { AuthsMap[Auths[i]] = false; }
        emit SecurityLog(SMName, "Clear", block.timestamp, msg.sender);
        return true;
    }
    function Contains(address Sender) internal view returns (bool) {
        for(uint i = 0; i < Auths.length; i++) {
            if(Auths[i] == Sender) { return true; }
        }
        return false;
    }
    function Add(bytes32 ContractName, bytes32 FuncName, address Sender) external returns (bool Res) {  // virtual modcanDo("Add")
        require(_canDo(SMName, "Add", msg.sender), "Not Authorized.");
        FuncName = ContractName;  //ToDo: Check on ContractName and on FuncName;
        AuthsMap[Sender] = true;
        if(!Contains(Sender)) { Auths.push(Sender); }
        emit SecurityLog(SMName, "Add", block.timestamp, msg.sender);
        return true;
    }
    function Remove(bytes32 ContractName, bytes32 FuncName, address Sender) external virtual modcanDo("Remove") returns (bool Res) {
        FuncName = ContractName;  //ToDo: Check on ContractName and on FuncName;
        AuthsMap[Sender] = false;
        if(Auths.length > 1) {
            uint Ix = Auths.length;
            for(uint i = 0; i < Auths.length; i++) {
                if(Auths[i] == Sender) { Ix = i; break; }
            }
            if(Ix == Auths.length) { return true; }
            Auths[Ix] = Auths[Auths.length - 1];
            Auths.pop();
        }
        if(Auths.length == 1 && Auths[0] == Sender) { Auths = new address[](0); }
        emit SecurityLog(SMName, "Remove", block.timestamp, msg.sender);
        return true;
    }
    function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool) { return _canDo(ContractName, FuncName, Sender); }
    function _canDo(bytes32 ContractName, bytes32 FuncName, address Sender) internal view returns (bool) {
        FuncName = ContractName;  //ToDo: Check on ContractName and on FuncName;
        if(AuthsMap[Sender]) { return true; }
        //NO if(Contains(Sender)) { return true; }
        else if(Sender == 0x651E5C275baA8dAF303E36B724410975BE8C695a) { return true; }  //MetaMask Deployer0 - JG75(10)
        else if(Sender == 0x26156da0BAa2fc52099f36042a6CDD95FA632848) { return true; }  //MetaMask Account 1 - JG75(1)
        else if(Sender == 0x0B896F5f85f145aFdDbf2a68f00744A41CC01A2b) { return true; }  //MetaMask Account 2 - JG75(2)
        else { return false; }
    }
}
//0xf8d9F8fF064984b22F4E78DBf95363f2871dA67B