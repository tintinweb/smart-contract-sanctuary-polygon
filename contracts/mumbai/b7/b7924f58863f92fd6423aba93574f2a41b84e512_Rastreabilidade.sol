/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: Logicalis
pragma solidity >=0.7.0 <0.9.0;

contract Rastreabilidade {
    address owner;

    struct Data {
        string origin;
        string destino;
        uint256 timestamp;
        string description;
        string fileHash;
        string local;        
    }
   
    Data public data;    
    Data[] public transacoes;   

    function _onlyOwner() private view{
        require(msg.sender == owner,"Not Owner");
    }
   
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    event RastreabilidadeCreated(Rastreabilidade wallet);
   
    constructor(
        string memory _origin,
        string memory _destino,
        uint256 _timestamp,        
        string memory _description,
        string memory _fileHash,
        string memory _local        
    ) {
       owner = msg.sender;
       data.origin = _origin;       
       data.destino = _destino;       
       data.timestamp = _timestamp;
       data.description = _description;
       data.fileHash = _fileHash;   
       data.local = _local;   
       transacoes.push(data);
       emit RastreabilidadeCreated(this);
    }
    
    function getData() public view returns (Data memory) {
        return data;
    } 

    function ObterDadosTransacao(string memory origin) public view returns (Data memory) {
        Data memory dataResultado;
        for (uint i = 0; i < transacoes.length; i++) {            
            
            //if (transacoes[i].origin == origin) {
            if(stringsEquals(transacoes[i].origin,origin)){
                dataResultado = transacoes[i];
                break;
            }
        }

        return dataResultado;
    }    

    function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i=0; i<l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }    

    function criarNovaRastreabilidade(
        string memory _origin,    
        string memory _destino,   
        uint256 _timestamp,        
        string memory _description,
        string memory _fileHash,
        string memory _local
    ) onlyOwner public {        

        data.origin = _origin;       
        data.destino = _destino;       
        data.timestamp = _timestamp;
        data.description = _description;
        data.fileHash = _fileHash;        
        data.local = _local;   

        transacoes.push(data);      
    }    
}