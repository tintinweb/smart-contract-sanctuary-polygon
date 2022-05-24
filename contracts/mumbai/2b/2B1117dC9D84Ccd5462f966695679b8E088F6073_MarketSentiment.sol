//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketSentiment{

    // variables, tiempo, dueño y lista de criptos
    uint256 voteTime;
    address public owner;
    string[] public tickersArray;

    // determina que el dueño de este contracto es quien lo suba a la blockchain
    // deterina que el tiempo empieza a contar desde el deployment 
    constructor(){
        owner = msg.sender;
        voteTime = block.timestamp;
    }

    // estructura del ticker
    struct ticker{
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    // evento para avisar cuando alguien vota, en que cripto y si es up o down
    event tickerupdated(
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    // mapping que toma un nombre "string" por ejemplo BTC o ETH, etc y lo relaciona con la estructura ticker creada anteriomente
    mapping(string => ticker) private Tickers;

    // función que permite que el dueño cree Tickers, es determinada como publica para que pueda ser llamada por el dueño externalmente
    // linea 2: requiere que el que este llamando la funcion sea el dueño
    // linea 3: creando una variable "newTicker" que guardara la representacion temporaria de la estructura "ticker" del _ticker que se esta creando hasta que bool sea determinado como true
    // linea 4: creando una nueva variable "newTicker" que indicara a mi struct que bool deve ser determinado como true, este ticker ahora si existe
    // linea 5: insertando el tiempo de creacion del newTicker
    // linea 6: adicionando este nuevo _ticker a la lista tickersArray
    function addTicker(string memory _ticker) public{
        require (msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    // linea 1: funcion que permite votar up o down
    // linea 2: verificando que el _ticker creado en la funcion addTicker, fue adicionado al mapping Tickers y que bool status es exists
    // linea 3: verificando si el usuario ya ha votado para un especifico ticker
    // linea 4: creando una variable "t" que guardara la representacion temporaria de la estuctura "ticker"  para el _ticker que el usuario esta votando el cual ya verificamos que si estan en la lista Ticker 
    // linea 5: relacionando la variable "t" con el mapping Voter y asignando la respuesta " true" para indicar que este usuario "msg.sender" ya ha votado por esta moneda y en caso intente votar nuevamente el requerimiento de la linea 2 impedira que pueda votar denuevo.
    // linea 6: determinando si el voto es up=true o down=false
    // linea 7: emitiendo el evento para que pueda ser captado en la base de datos de Moralis
    function vote(string memory _ticker, bool _vote) public{
        require(Tickers[_ticker].exists, "Cant vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin, try again in 10min");
    
            ticker storage t = Tickers[_ticker];
            t.Voters[msg.sender] = true;
            
        if(_vote){
            t.up++;
        } else{
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    //function que permite VOLVER a votar luego de 10MIN
    function voteAgain(string memory _ticker, bool _vote) public{
        require(Tickers[_ticker].exists, "Cant vote on this coin");
        require(block.timestamp - voteTime > 600, 'Need to wait 10 minutes');
                     
            ticker storage t = Tickers[_ticker];
            t.Voters[msg.sender] = true;
            
        if(_vote){
            t.up++;
        } else{
            t.down++;
        }

        voteTime = block.timestamp;

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }


    // linea 1: declarando encabezado de funcion que retorna los votos up/down que ha recibido cada moneda
    // linea 2: indicando que debe retornar los votos up
    // linea 3: indicando que debe retornar los votos down
    // linea 4: verificando que el _ticker al que se quiere ver fue creado en la funcion addTicker, fue adicionado al mapping Tickers y que bool status es exists
    // linea 5: creando una variable "t" que guardara la representacion temporaria de la estuctura "ticker"  para el _ticker que el usuario esta votando el cual ya verificamos que si estan en la lista Ticker 
    // linea 6: retornando los valores up o down de la variable "t" 
    function getVotes(string memory _ticker) public view returns(
        uint256 up,
        uint256 down
    ){
        require(Tickers[_ticker].exists, "No such ticker defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}