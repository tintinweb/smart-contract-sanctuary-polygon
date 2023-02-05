/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

pragma solidity ^0.4.24;
 
//Safe Math Interface
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function uintToString(uint v) public pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i] = byte(48 + remainder);
            i++;
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        str = string(s);
    }
    function random() external view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, 
        block.difficulty)));
    } 
    function uint6_index(uint v) public pure returns (bytes byt) {
        uint maxlength = 6;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while ( i < 6 ) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        byt = s;
    }
    function byte_to_address(bytes32 data) external pure returns (address) {
        return address(data);
    }
    function newaddr(uint _type,uint index_ ,uint rand) public pure returns(address addr) {
        uint v = index_;
        uint i = 0;
        uint256 add = 0;
        uint8[6] memory data ;
        while ( v != 0 ) {
            data[i] = uint8(v % 10);
            v = v / 10;
            i++;
        }
        uint secret = rand;
        add = (_type << 4)  + data[5];
        add = (add<<8) + (data[4]<<4)  + (secret % 10);
        secret = secret / 10;
        add = (add<<8) +  (data[3]<<4)  + (secret % 10);
        secret = secret / 10;
        add = (add<<8) +  (data[2]<<4)  + (secret % 10);
        secret = secret / 10;
        add = (add<<8) + (data[1]<<4)  + (secret % 10);
        secret = secret / 10;
        add = (add<<8) +  (data[0]<<4)  + (secret % 10);
        addr = address(add);
    }
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        string memory v = uintToString(bytes(_message).length);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n",v,_message));
    }
    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    function VerifyMessage(string memory _message, bytes memory _signature) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_message);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = ecrecover(messageHash, v, r, s);
        return signer;
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract VHCTtoken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public minter;
    uint private index_ ;
    uint private pr_3_index_ ;
    uint public token_fee;
    address private zero_key;
 
    mapping(address => uint) balances;
    mapping(address => uint) VNDs;
    mapping(address => uint) vouchers;
    mapping(address => address) PrtoPu;
    mapping(address => address) erc20_vch;
    mapping(address => uint) Pr_balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => address[]) puhaspr;

    event Supply(address from, address to, uint amount);
    event Getvoucher(address from, address to, uint amount);
    event GetVND(address from, address to, uint amount);
    event createKeyevent(address from, uint count, uint amount);

    constructor() public {
        symbol = "VCH";
        name = "Voucher Token";
        decimals = 3;
        _totalSupply = 9000000*10**3;
        minter = msg.sender;
        balances[address(1)] = _totalSupply;
        erc20_vch[minter] = address(1);
        uint secret = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%99999);
        address n_private =  newaddr(1,1 ,secret);
        PrtoPu[n_private] = address(1);
        emit Transfer(address(1), minter, _totalSupply);
        index_ = 2;
        pr_3_index_ = 0;
        token_fee = 0;
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[erc20_vch[tokenOwner]];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[erc20_vch[msg.sender]] = safeSub(balances[erc20_vch[msg.sender]], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(erc20_vch[msg.sender], to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        if (balances[erc20_vch[msg.sender]] < tokens) return false;
        allowed[erc20_vch[msg.sender]][spender] = tokens;
        emit Approval(erc20_vch[msg.sender], spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (balances[from] < tokens) return false;
        if (allowed[from][erc20_vch[msg.sender]]  < tokens) return false;
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][erc20_vch[msg.sender]] = safeSub(allowed[from][erc20_vch[msg.sender]], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[erc20_vch[msg.sender]][spender] = tokens;
        emit Approval(erc20_vch[msg.sender], spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(erc20_vch[msg.sender], tokens, this, data);
        return true;
    }
    //-----------------------------------------------------------------------------
    function supplyTo(address to, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        if (balances[minter] < tokens) return false;
        balances[erc20_vch[minter]] = safeSub(balances[erc20_vch[minter]], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Supply(msg.sender, to, tokens);
        return true;

    }
    function getVouform(address form, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        uint type_ad = 0xf00000000000;
        type_ad = type_ad & uint(form);
        if(type_ad == 1){
            address form_1 = PrtoPu[form];
            if (balances[form_1] < tokens) return false;
            balances[form_1] = safeSub(balances[form_1], tokens);
            vouchers[form_1] = safeAdd(vouchers[form_1] , tokens);
            emit Getvoucher(form_1,address(0),tokens);
            return true;
        }
        if(type_ad > 1){
            if (Pr_balances[form] < tokens) return false;
            Pr_balances[form] = safeSub(Pr_balances[form], tokens);
            vouchers[form] = safeAdd(vouchers[form] , tokens);
            emit Getvoucher(address(0),address(0),tokens);
            return true;
        }
        return false;
    }
    function getvndform(address form, uint tokens) public returns (bool success) {
        if(minter != msg.sender) return false;
        uint type_ad = 0xf00000000000;
        type_ad = type_ad & uint(form);
        if(type_ad == 1){
            address form_1 = PrtoPu[form];
            if (balances[form_1] < tokens) return false;
            balances[form_1] = safeSub(balances[form_1], tokens);
            VNDs[form_1] = safeAdd(VNDs[form_1] , tokens);
            emit GetVND(form_1,address(0),tokens);
            return true;
        }
        if(type_ad > 1){
            if (Pr_balances[form] < tokens) return false;
            Pr_balances[form] = safeSub(Pr_balances[form], tokens);
            VNDs[form] = safeAdd(VNDs[form] , tokens);
            emit GetVND(address(0),address(0),tokens);
            return true;
        }
        return false;
    }
   function voucherOf(address tokenOwner) public constant returns (uint voucher) {
        return vouchers[tokenOwner];
    }
   function vndOf(address tokenOwner) public constant returns (uint vnd) {
        return VNDs[tokenOwner];
    }
    function createKey(address form_1, uint total, uint _type, uint tokens) public returns (bool success) {
        uint v = 0;
        uint secret = 0;
        address n_public;
        address n_private;
        address form = PrtoPu[form_1];
        secret = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%99999);
        uint public_secret = 31245; 
        if((form != erc20_vch[msg.sender])&&(minter != msg.sender) ) return false;
        if (balances[form] < ((total*tokens)+token_fee)) return false;
        balances[form] = safeSub(balances[form], token_fee);
        while ( v < total ) {
            if(_type == 0){
                if (balances[form] < tokens) return false;
                n_public =  newaddr(0,index_ ,public_secret);
                secret = secret + 143 * v + tokens + total + index_ + pr_3_index_;
                n_private =  newaddr(1,index_ ,secret);
                PrtoPu[n_private] = n_public;
                balances[n_public] =  tokens; 
                puhaspr[form].push(n_private);
                balances[form] = safeSub(balances[form], tokens);
                index_++;
            }
            if(_type == 1){
                secret = secret + 143 * v + tokens + total + index_ + pr_3_index_;
                uint pr_3_ind1 = pr_3_index_ % 999999;
                uint pr_3_ind2 = (pr_3_index_ / 999999) + 2 ;
                if (balances[form] < tokens) return false;
                n_private =  newaddr(pr_3_ind2,pr_3_ind1 ,secret);
                Pr_balances[n_private] =  tokens; 
                balances[form] = safeSub(balances[form], tokens);
                puhaspr[form].push(n_private);
                pr_3_index_++;
            }
            v++;
        }
        emit createKeyevent(form, v, tokens);
        return true;
    } 
    function checkkey(address form) public constant returns  (address[] memory pr) {
        address r = PrtoPu[form];
        return puhaspr[r];
    }
    function getPubkey(address form) public constant returns  (address pr) {
        return PrtoPu[form];
    }
    function get_zero_key(bytes memory _signature) public constant returns (address rt) {
        string memory message = "123456";
        address ver = VerifyMessage(message,_signature);
        if(ver == minter){return zero_key;}
    }
    function set_pu_erc20(address form,address erc20) public returns  (bool success) {
        if(minter == msg.sender) {
            erc20_vch[erc20] = form;
        }
        return false;
    }
}