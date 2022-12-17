/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// File: dFuture/demo.sol



pragma solidity >=0.7.0 <0.9.0;

contract Contrato{

    enum Status {naoIniciado, emAndamento, expirado, concluido, emDisputa}
    enum StatusPagamento {naoDepositado, depositado}
    enum StatusEntrega { naoEntregue, entregue}

    address payable public carteiraFreelancer;
    address payable public carteiraContratante;
    address public carteiraArbitro;
    Status public status;
    StatusPagamento public statuspag;
    StatusEntrega public statusentrega;
    //int256 public totalAcordos = 0;

    struct acordo{
        string nome;
        uint256 dataEntrega;
        string descricao;
        Status status;
    }
   
    bool encerraFreela = false;
    bool encerraCliente = false;

    mapping(int256 => acordo) public registroDeAcordo;

    modifier onlyArbitro(){
        require(msg.sender == carteiraArbitro);
		_;
    }

    modifier onlyFreelancer() {
		require(msg.sender == carteiraFreelancer);
		_;
	}

	modifier onlyClient() {
		require(msg.sender == carteiraContratante);
		_;
	}
	
	modifier bothClientFreelancer(){
		require(msg.sender == carteiraContratante || msg.sender == carteiraFreelancer);
		_;	    
	}

	modifier statusDoProjeto(Status _status) {
		require(status == _status);
		_;
	}

    modifier statusDoPagamento(StatusPagamento _status){
        require(statuspag == _status);
        _;
    }

    event acordoAdicionado(string _nome); //???
    event deposit( //?? pra q esses events
        address indexed _from,
        uint256 _value
    );
    event pay( 
        address indexed _from,
        uint256 _value
    );

    constructor()
    {
        carteiraContratante = payable(msg.sender); //??
        status = Status.naoIniciado;
    }

    function novoAcordo(string memory _nome,string memory _descricao, uint256 _dataEntrega, address payable  _carteiraFreelancer)
    public
    statusDoProjeto(Status.naoIniciado)
    onlyClient
    {
        acordo memory a;
        a.nome = _nome;
        a.descricao = _descricao;
        a.dataEntrega = block.timestamp + _dataEntrega *60*60*24 ; // RONNIE ME AJUDA
        registroDeAcordo[1] = a; //??
        carteiraFreelancer = _carteiraFreelancer;
        //totalAcordos++;
        status = Status.emAndamento;
        emit acordoAdicionado(_nome);
    }

    function transfer() 
     private
     statusDoProjeto(Status.concluido)
    {
        carteiraFreelancer.transfer(address(this).balance);
        
        emit pay(carteiraFreelancer,address(this).balance); 

    }

    function depositar()
    payable
    public
    onlyClient
    statusDoPagamento(StatusPagamento.naoDepositado)
    {
        require(msg.value > 0, "Must send Ether");
        //registroDeAcordo[1].valor = msg.value;
        statuspag = StatusPagamento.depositado;
        emit deposit(msg.sender,msg.value);
    }


    function entregar()
    public
    onlyFreelancer
    statusDoPagamento(StatusPagamento.depositado)
    statusDoProjeto(Status.emAndamento)
    {
        encerraFreela = true;
        statusentrega = StatusEntrega.entregue;
        //algum tipo de mensagem para avisar que agora o cliente tem que aprovar a entrega
    }

    function confirmar_entrega()
    public
    onlyClient
    statusDoPagamento(StatusPagamento.depositado)
    statusDoProjeto(Status.emAndamento)
    {
        encerraCliente = true;
        finalizarAcordo();
        transfer();
    }

    function solicitar_disputa()
    public 
    bothClientFreelancer
    statusDoPagamento(StatusPagamento.depositado)
    {
        require(status == Status.expirado || statusentrega == StatusEntrega.entregue, "O contrato deve estar expirado ou o produto deve estar entregue pelo freelancer");
       
        status = Status.emDisputa;
    }

    function finalizarAcordo()
    private
    {
        if(encerraFreela == true && encerraCliente == true){
            status = Status.concluido;
        }
        else{
            require(encerraFreela == true , "O freelancer precisa informar a entrega antes do cliente poder confirmar a entrega");
        }
    }

    function contratoExpirado(uint256 dataExpirar) //função deve ser chamada periodicamente
    private
    {
        if (block.timestamp >= dataExpirar) status = Status.expirado;
    }
    

    function clienteVenceArbitragem()
    public
    onlyArbitro
    statusDoPagamento(StatusPagamento.depositado)
    statusDoProjeto(Status.emDisputa)
    {
        carteiraContratante.transfer(address(this).balance);
        
        emit pay(carteiraContratante,address(this).balance);
    }

    function freelancerVenceArbitragem()
    public
    onlyArbitro
    statusDoPagamento(StatusPagamento.depositado)
    statusDoProjeto(Status.emDisputa)
    {
        carteiraFreelancer.transfer(address(this).balance);
        
        emit pay(carteiraFreelancer,address(this).balance);
    }

    function registroDeArbitro ()
    public
    statusDoPagamento(StatusPagamento.depositado)
    statusDoProjeto(Status.emDisputa)
    {
        require(msg.sender != carteiraFreelancer && msg.sender != carteiraContratante, " Freelancers e Clientes nao podem ser arbitros do proprio acordo");
        carteiraArbitro = msg.sender;
    }
}