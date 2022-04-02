/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/rps.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;



interface IRandomNumberVRF{
    function getRandomNumber() external returns (bytes32 requestId);
    function getRandomRangeNumber(address _user, uint a, uint b) external returns(uint256);
}
interface IstakingNFT{
    function newPlay() external payable;
}
contract rpsGame is Ownable, ReentrancyGuard  { 

    //address owner; // Dueño del contrato, maximo rango de acceso (mover fondos de la pool)
    IRandomNumberVRF randomLinkContract; //Direccion de VRF random contract
    //address payable addressStaking;
    IstakingNFT NFTHolders; //Direccion de contrato staking
    address devWalletFees;  //Direccion del fee para los devs

    uint public feeForNFTHolders = 250; //% del fee para nftHolders (100 = 1%)
    uint public feeForDevs = 100; //Fee para los del equipo de desarrollo

    bool public onOff = true; // to pause play function
    uint totalFee = feeForNFTHolders + feeForDevs;
    uint maxDeal; //Max Value in Play fuction
    uint minBalanceToPay; // balance minimo que tiene que tener el contrato, para poder pagar.
    uint protectedTime = 3;
    mapping (address => uint) public debtPerUser; //Usado para pagar las deudas.
    uint public totalDebt;
    
    //string[3] RPSop = ['rock','paper', 'scissors']; // 0 = Rock, 1 = paper, 2=scissors
    //for testin gass
    uint public totalWins;
    uint public totalLoses;
    mapping(address => uint[2])  winLosesPerUser;
    mapping(address => uint[2])  winLosesRache;

    mapping(address => uint)  timeLock; //Tiempo entre partidas para un mismo address
/*
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
*/
   
//EVENTS
    event Play(address user,uint bid,uint racha,bool result,uint random, bool debt);// User ,apuesta ,racha, result, NumeroAleatoreo
    event C_setNFTHoldersAddress(address Sender,address oldAddress,IstakingNFT); // C_(Change), (Msg.sender,NewAdrres)
    event C_setDevAddress(address Sender,address oldAddress, address newAddress);//Change devWalletFees (msg.sender, NewAddress)
    event C_setFeeForNFTHolders(address,uint);// Change feeForNFTHolders(msg.sender, newValue)
    event C_setFeeForDevs(address,uint);// Change feeFordevs(msg.sender, newValue)
    event C_setMaxDeal(address,uint);// change max value in Play fuction (msg.sender, newMaxValue)
    event FoundsIn(address, uint);//
    event FoundsOut(address,uint,address); // withdraw found of this contract(msg.sender, total, address founds)
    //event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (        
        address _devWallet, 
        address payable _NFTholders,
        uint _maxDeal,
        uint _minBalanceToPay
    ){
        //addressStaking = _NFTholders;
        NFTHolders = IstakingNFT(_NFTholders);
        devWalletFees = _devWallet;
        maxDeal = _maxDeal * 1 ether;
        minBalanceToPay = _minBalanceToPay * 1 ether;
    }

//FUNCTIONS FOR USERS

    //MSG.value = deal + totalFEE%
    function play( uint _value) public payable nonReentrant  returns(bool results){
        require(onOff == true, "Play in pause");
        require((timeLock[msg.sender] + protectedTime) < block.timestamp );
        uint fee = calculateFee(_value);
        require(msg.value <= (maxDeal + fee));
        require(msg.value > 0);
        require( (_value+fee) == msg.value);
        timeLock[msg.sender] = block.timestamp;

        payable(devWalletFees).transfer(_value * feeForDevs  / 10000);
        NFTHolders.newPlay{value:(_value * feeForNFTHolders / 10000)}();
        //getRandom is internal!
        uint rand = getRandomRangeLink(msg.sender,1,100);
        bool debt = false;
        if(rand >= 50){
            if(checkBalance(_value * 2)){
                payable(msg.sender).transfer(_value * 2);
            }else {
                payable(msg.sender).transfer(_value);
                debtPerUser[msg.sender] += _value;
                totalDebt += _value;
                debt = true;
            }            
            results = true;
            totalWins++;
            winLosesPerUser[msg.sender][1]++;
            winLosesRache[msg.sender][0]++;
            if(winLosesRache[msg.sender][0] > winLosesRache[msg.sender][1]){
                winLosesRache[msg.sender][1] == winLosesRache[msg.sender][0];
            }
            //liquidity.win(msg.sender, _value);
        }else {
            results = false;
            totalLoses++;
            winLosesPerUser[msg.sender][0]++;
            delete winLosesRache[msg.sender][0];            
        }
        
        emit Play(msg.sender,_value,winLosesRache[msg.sender][0],results,rand, debt);
        //leaderBoard(result)

    }

    function claimDebt() public nonReentrant{
        require (checkBalance(debtPerUser[msg.sender]) == true);
        require(debtPerUser[msg.sender] > 0, "no tiene fondos para claimear" );
        uint toPay = debtPerUser[msg.sender];
        totalDebt -= toPay;
        delete debtPerUser[msg.sender];
        payable(msg.sender).transfer(toPay);
    }
   
//other functions
    function calculateFee(uint _value)public view returns(uint){
        uint txFee = _value * totalFee / 10000;
        return txFee;
    }

    function calculateValue(uint _value)public view returns(uint){
        uint totalValue = calculateFee(_value) + _value;
        return totalValue;
    }

    function viewTimeProtected(address _address) public view returns(uint){
        return timeLock[_address];
    }

    //trasnfiere valor, usao para testeo
    function trasnferFoundsIN()public payable returns(bool){
        require(msg.value > 10);
        emit FoundsIn(msg.sender,msg.value);
        return true;
    }

//internal
    function getRandomRangeLink(address _user,uint a, uint b) internal returns(uint){
        uint random = randomLinkContract.getRandomRangeNumber(_user,a,b);
        if (random == 0 ) {random = 1;}
        return random;
    }
    
    function checkBalance(uint _value) internal view returns(bool){
        if((address(this).balance) + _value > minBalanceToPay){
            return true;
        }else {
            return false;
        }
    }

//SETTERS

    //Cambiar direccion del contrato a donde va el 2% para los que posen nfts
    function setNFTHoldersAddress(address payable _newNFTholders) public onlyOwner{
        IstakingNFT oldNFT = NFTHolders;
        NFTHolders = IstakingNFT(_newNFTholders);
        emit C_setNFTHoldersAddress(msg.sender, address(oldNFT), IstakingNFT(_newNFTholders));
    }

    //Cambiar la direccion donde va el 1.5%(devFee)
    function setDevAddress(address _newDevWalletFees) public onlyOwner {
        address oldAdd = devWalletFees;
        devWalletFees = _newDevWalletFees;
        emit C_setDevAddress(msg.sender, oldAdd, devWalletFees);
    }

    //Cambia el % de fee que es destinado a holders
    function setFeeForNFTHolders(uint _newFeeForNFTHolders) public onlyOwner{
        require((feeForDevs + _newFeeForNFTHolders) < 2000);
        feeForNFTHolders = _newFeeForNFTHolders;
        totalFee = feeForNFTHolders + feeForDevs;
        emit C_setFeeForNFTHolders(msg.sender,_newFeeForNFTHolders);
    }

    //Cambia el % de fee que es destinado a Devs
    function setFeeForDevs(uint _newFeeForDevs) public onlyOwner{
        require((_newFeeForDevs+feeForNFTHolders) < 5000);
        feeForDevs = _newFeeForDevs;
        totalFee = feeForNFTHolders + feeForDevs;
        emit C_setFeeForDevs(msg.sender,_newFeeForDevs);
    }

    //Cambia el maximo disponible en una misma jugada.
    function setMaxDeal(uint _newMaxDeal) public onlyOwner{
        require(_newMaxDeal > ((address(this).balance)/10));
        maxDeal = _newMaxDeal;
        emit C_setMaxDeal(msg.sender,_newMaxDeal);
    }

    function setIRandomNumberVRF(IRandomNumberVRF _randomLinkContract) public onlyOwner{
        randomLinkContract = _randomLinkContract;
    }

    //min balance in this contract, to pay 
    function setMinBalanceToPay(uint _minBalance) public onlyOwner(){
        minBalanceToPay =_minBalance;
    }

    function setProtectedTime(uint _NewprotectedTime) public onlyOwner(){
        protectedTime = _NewprotectedTime;
    }

    //funcion que pone en pausa el juego.
    function pause(bool _bool)public onlyOwner{
         onOff = _bool;
    }

    function trasnferFoundsOUT(uint _amount, address _to) public payable onlyOwner(){
        payable(_to).transfer(_amount);
        onOff = false;
        emit FoundsOut(msg.sender, _amount,_to);
    }

    function timeBlock() public view returns(uint){
        return block.timestamp;
    }

    /* Codig by @Patoverde - 2022*/
    
}