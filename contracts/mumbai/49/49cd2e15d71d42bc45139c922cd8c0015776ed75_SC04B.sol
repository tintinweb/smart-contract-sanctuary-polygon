/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAUX {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract SC04B {

    /**  _nextToken para saber el siguiente token a transferir */
    uint private _nextToken;
    
    // Creo una variable tipo IAUX llamada tokenContract
    IAUX tokenContract;
    // VARIABLE TIPO IERC721 -> osea variable de tipo interfaz

    /**ADDRESS DEL OWNER DE TODOS LOS TOKENS AL MOMENTO DE DEPLOYAR */
    address private _deployer;

    /**AL CONSTRUCTOR LE PASO EL ADDRESS DEL SC QUE TIENE EL NFT (SC04) LUEGO DEL DEPLOY*/
    constructor(address tokenSC_, address deployer_) {
        /**
         -> indico que el primer token a transferir sera el 0
         -> alamceno en token contract la inicializacion? de IAUX con el addres del token_ (sc04 deployed) el sc con
         el que interactuara este SC (SC04B) pero mediante el metodo transferFrom
        */
        _nextToken = 0;
        tokenContract = IAUX(tokenSC_); // chequea que _token sea un SC y poseea codigo , de momento la implementacion de la funcion transferFrom no importa
                                      // si esto sucede almacenara el selector de la funcion que se encuentra en la interfaz, en este caso alamaenara 
                                      // tranfserFrom(address from, address to, uint256 tokenId)
        _deployer = deployer_;
    }
    /**FUNCION QUE PERMITE LA COMPRA DE CADA NFT A UN PRECIO DE 0.01 ETHER 
     -> address to es la direccion a donde se enviara el token
     -> amount es la cantidad de tokens a enviar (tendra que coincidir con la cantidad de ether enviado)
    */
    function buyNFT(address to,uint amount) public payable {
        /**
         -> el ether enviado no puede ser mayor que 10 
         -> el ether enviado tiene que ser mayor o igual al precio de la cantidad de tokens a comprar
         */
        require(amount <= 10 , 'Amount exceeds limit');
        require(msg.value == (amount * 0.01 ether), 'Invalid msg.value');
        
        /**CICLA N VECES SIENDO N LA CANTIDAD DE TOKENS COMPRADOS */
        for (uint i = 0 ; i < amount; i++){
            /**
             -> llama a la funcion trasnferFrom definida previamente en la interfaz de este SC y tambien definida
             en el SC del token a transferir , en este caso SC04
             -> incrementa nextToken guardando asi el siguiente token a transferir
             */
            tokenContract.transferFrom(_deployer, to , _nextToken); //interactua con la funcion transferFrom del ERC721 del q hereda _token (SC04)
            _nextToken++;
        }
    }

    function withdraw() public payable {
        require(msg.sender == _deployer, 'Not permitted');
        payable(msg.sender).transfer(getBalance());
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}