/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract LotteryBattle {

  struct Map {
    uint[] keys;
    mapping(uint => address) values;
  }

  mapping(uint => Map) private sistema;
  mapping(uint => uint) private premios;
  mapping(address => mapping(uint => bool)) public pagos;
  uint[] public tiempos;
  address payable public immutable ceoAddress;
  uint public constant PRICE = 250000000000000000;

  event Log(uint ganador, uint montoG, uint perdedor, uint montoP);

  constructor(){
    ceoAddress=payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == ceoAddress, "Not owner");
    _;
  }

  function comprar(uint[] memory numeros, uint time) public payable{
    uint len=numeros.length;
    require(msg.value==(PRICE*len), "Incorrect Amount");
    uint a = hayGanador(sistema[time].keys,numeros);
    require(a==0, "Number already buy");
    for (uint i = 0; i < len; i++) {
      sistema[time].keys.push(numeros[i]);
      sistema[time].values[numeros[i]] = msg.sender;
    }
  }

  function retirar(uint time) public{
    require(pagos[msg.sender][time]==false, "Already Pay");
    uint[] memory winners = ganadores(time);
    uint[] memory userNum = getTablaUser(time,msg.sender);
    uint len = sistema[time].keys.length;
    uint leng = winners.length;
    uint256 pagoganador = SafeMath.mul(PRICE,2);
    uint256 pagogerdedor = SafeMath.div(SafeMath.sub(SafeMath.mul(PRICE, len),SafeMath.mul(pagoganador,leng)),SafeMath.sub(len,leng));
    uint monto;
    uint a = hayGanador(winners,userNum);
    if(a > 0){
      monto += SafeMath.mul(pagoganador,a);
    }
    if(pagogerdedor>0){
      monto += SafeMath.mul(pagogerdedor,(userNum.length-a));
    }
    if(monto == 0){
      revert("There is no prize");
    }else if(monto>0){
      pagos[msg.sender][time]=true;
      uint fee=devFee(monto);
      ceoAddress.transfer(fee);
      payable(msg.sender).transfer(SafeMath.sub(monto,fee));
    }
  }

  function devFee(uint amount) public pure returns(uint){
    return SafeMath.div(SafeMath.mul(amount,10),100);
  }

  function getTablaUser(uint time, address user) public view returns (uint[] memory){
    uint len=sistema[time].keys.length;
    uint[] memory u = new uint[](len);
    uint y;
    for (uint i = 0; i < len; i++) {
      uint num=sistema[time].keys[i];
      if(sistema[time].values[num]==user){
        u[y]=num;
        y++;
      }
    }
    return(afinar(u,y));
  }

  function getTabla(uint time) public view returns (uint[] memory){
    return sistema[time].keys;
  }

  function ganadores(uint time) public view returns(uint[] memory){
    uint num = premios[time];
    uint[] memory tickets = sistema[time].keys;
    uint len = tickets.length;
    tickets = ordenar(tickets,num,len);
    uint[] memory ga = new uint[](len);
    uint256 win;
    uint256 j;
    while (win<len) {
      if (len-1 >= win+1) {
        win++;
        len--;
        ga[j]=tickets[j];
        j++;
      }else{win++;}
    }
    if(modulo(tickets[j],num) == modulo(tickets[j-1],num)){
      ga[j-1]=0;
      j--;
    }
    return(afinar(ga,j));
  }

  function afinar(uint[] memory datos, uint len) public pure returns(uint[] memory){
    uint[] memory result = new uint[](len);
    for (uint i = 0; i < len; i++){
      result[i]=datos[i];
    }
    return(result);
  }

  function ordenar(uint[] memory arr, uint valor, uint len) public pure returns(uint[] memory){
    for (uint i = 0; i < len; i++){
      for (uint j = i+1; j < len; j++){
        if (modulo(arr[i],valor) > modulo(arr[j],valor)){
          uint tmp = arr[i];
          arr[i] = arr[j];
          arr[j] = tmp;
        }
      }
    }
    return arr;
  }

  function hayGanador(uint[] memory gan,uint[] memory usuario) public pure returns(uint){
    uint a;
    uint len=gan.length;
    uint len2=usuario.length;
    for (uint i = 0; i < len; i++){
      for (uint j = 0; j < len2; j++){
        if(gan[i]==usuario[j]){
          a++;
        }
      }
    }
    return a;
  }

  function modulo(uint256 a, uint256 b) public pure returns(uint256){
    if(a >= b) {return a - b;}else{return b - a;}
  }

  function generar(uint time) public onlyOwner{
    uint win = 10;
    tiempos.push(time);
    premios[time]=win;
  }

  function random() private view returns(uint){
    return uint(keccak256(abi.encodePacked(msg.sender,block.difficulty,block.timestamp))) % 100;
  }

  
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}