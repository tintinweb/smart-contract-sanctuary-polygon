/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract  USDT_FREC is ReentrancyGuard {
    address public owner;

    address public USDT_addr = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public FREC_addr = 0x09a84F900205B1ac5f3214d3220C7317FD5F5b77;

    uint public USDT_dec = 6;
    uint public FREC_dec = 18;

    uint public FRECPerUSDT = 1 * (10 ** FREC_dec);

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function Buy_Frec(uint input_amount_in_USDT) public nonReentrant returns(bool){
        require(input_amount_in_USDT !=0 ,"input amount cannot be zero");
        uint amount_of_frec_to_send = (input_amount_in_USDT * (10**FREC_dec) * (FRECPerUSDT )) / ((10 **USDT_dec) * ( 10** FREC_dec) );
        require(amount_of_frec_to_send <= ERC20(FREC_addr).balanceOf(address(this)),"Not enough Liquidity(FREC)");
        require(input_amount_in_USDT <= ERC20(USDT_addr).allowance(msg.sender,address(this)),"allowance is not provided for ERC20 transaction");
        ERC20(USDT_addr).transferFrom(msg.sender,address(this),input_amount_in_USDT);
        ERC20(FREC_addr).transfer(msg.sender,amount_of_frec_to_send);
        return true;
    }


    function Buy_USDT(uint input_amount_in_FREC) public nonReentrant returns(bool){
        require(input_amount_in_FREC != 0 ,"input amount cannot be zero");
        uint amount_of_USDT_to_send = (input_amount_in_FREC * (10**USDT_dec) * (10 ** FREC_dec))/((10**FREC_dec)* (FRECPerUSDT));
        require(amount_of_USDT_to_send <= ERC20(USDT_addr).balanceOf(address(this)),"Not enough Liquidity(USDT)");
        require(input_amount_in_FREC <= ERC20(FREC_addr).allowance(msg.sender,address(this)),"allowance is not provided for ERC20 transaction");
        ERC20(FREC_addr).transferFrom(msg.sender,address(this),input_amount_in_FREC);
        ERC20(USDT_addr).transfer(msg.sender,amount_of_USDT_to_send);
        return true;
    }



    function Buy_Frec_mock(uint input_amount_in_USDT) public view returns(uint){
        require(input_amount_in_USDT !=0 ,"input amount cannot be zero");
        uint amount_of_frec_to_send = (input_amount_in_USDT * (10**FREC_dec) * (FRECPerUSDT )) / ((10 **USDT_dec) * ( 10** FREC_dec) );
        return amount_of_frec_to_send;
    }


    function Buy_USDT_mock(uint input_amount_in_FREC) public view  returns(uint){
        require(input_amount_in_FREC != 0 ,"input amount cannot be zero");
        uint amount_of_USDT_to_send = (input_amount_in_FREC * (10**USDT_dec) * (10 ** FREC_dec))/((10**FREC_dec)* (FRECPerUSDT));
        return amount_of_USDT_to_send;
    }

    function withdraw(address token,uint amount) public onlyOwner {
        ERC20(token).transfer(msg.sender,amount);
    }
    
    function NativeTokenWithdraw(uint amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setFrecPrice(uint amountOfFRECPerUSDT) public onlyOwner {
        FRECPerUSDT = amountOfFRECPerUSDT;
    }

}