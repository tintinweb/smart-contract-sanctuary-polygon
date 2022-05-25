// SPDX-License-Identifier:no
import "./Counters.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
// import "./IPPtransfer.sol";
interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
pragma solidity ^0.8.2;

contract PPtransfer is Ownable, EIP712{
    address server;
    address monitor;
    uint256 mini_amount;
    address token;
    mapping(address=>bool)public auditor;
    constructor() EIP712("VIIDER_Withdraw_permit", "1"){
        // super.transferOwnership(address(0));
        set_info(0xbAa4C2f6B2E7751d52B7919E1ceF6516AC924684,0x4B70D185D81FE0189Ea939Fc51BF81e2715c6749,10**20,0x2Fd7A85139803b42f03D8fEb476e6FA26c1F5ceb);
    }
    function set_info(address _server,address _monitor,uint256 _mini_amount,address _token)public onlyOwner{
        server=_server;
        monitor= _monitor;
        mini_amount=_mini_amount;
        token =_token;
    }
    function show_info()public view returns(address _server,address _monitor,uint256 _mini_amount,address _token){
        return (server,monitor,mini_amount,token);
    }
    function p_set_auditor(address[] calldata _auditor,bool[]calldata flag)public onlyOwner{
        require(_auditor.length==flag.length,"VIIDER_Withdraw: length error");
        for(uint i;i<_auditor.length;i++){
            auditor[_auditor[i]]=flag[i];
        }
    }

    event e_Withdraw(address indexed sender,address indexed to,uint256 value,uint256 nonce);

    struct permit_sign{
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function Withdraw_permit_auditor (
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        // uint8[2] calldata v,
        // bytes32[2] calldata r,
        // bytes32[2] calldata s
        permit_sign[2] calldata signinfo
    ) public  {
        require(block.timestamp <= deadline, "VIIDER_Withdraw: expired deadline");
        emit e_Withdraw(owner,spender,value,_nonces[owner].current());
        // 验证服务器签名
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH,signinfo[0].v, signinfo[0].r, signinfo[0].s));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signinfo[1].v, signinfo[1].r, signinfo[1].s);
        require(signer == server, "VIIDER_Withdraw: server invalid signature");
        // 验证审核人员签名
        structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        hash = _hashTypedDataV4(structHash);
        signer = ECDSA.recover(hash, signinfo[0].v, signinfo[0].r, signinfo[0].s);
        require(signer == owner == auditor[owner], "VIIDER_Withdraw: auditor invalid signature");
        
        // 进行操作
        IERC20(token).transferFrom(super.owner(),spender,value);
    }

    function Withdraw_permit(
        address spender,
        uint256 value,
        uint256 deadline
    ) public  {
        require(block.timestamp <= deadline, "VIIDER_Withdraw: expired deadline");
        require(value <= mini_amount, "VIIDER_Withdraw: expired deadline");
        require(_msgSender()==server,"VIIDER_Withdraw: only server can transfer");
        emit e_Withdraw(server,spender,value,_nonces[server].current());

        IERC20(token).transferFrom(super.owner(),spender,value);
    }

    // function P_Withdraw_permit(
    //     address[] calldata spender,
    //     uint256[] calldata value,
    //     uint256[] calldata deadline,
    //     permit_sign[] calldata signinfo
    // ) public  {
    //     require((spender.length==value.length)==(deadline.length==value.length)==(deadline.length==signinfo.length),"VIIDER_Withdraw: length error");
    //     for(uint i;i<spender.length;i++){
    //         Withdraw_permit(spender[i],value[i],deadline[i],signinfo[i]);
    //     }
    // }

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _nonces;
    function nonces(address owner) public view  returns (uint256) {
        return _nonces[owner].current();
    }

    function _useNonce(address owner) internal returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    modifier onlyserver() {
        require(_msgSender() == server, "Ownable: caller is not the owner");
        _;
    }
    modifier onlymonitor() {
        require(_msgSender() == monitor, "Ownable: caller is not the owner");
        _;
    }
    bool public lock;
    function set_lock(bool flag)public monitor_lock{
        lock =flag;
    }
    modifier monitor_lock() {
        require(lock, "Ownable: caller is not the owner");
        _;
    }
}