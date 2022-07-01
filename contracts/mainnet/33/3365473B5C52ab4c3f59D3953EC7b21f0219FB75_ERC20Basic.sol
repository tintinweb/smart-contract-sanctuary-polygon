pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

/*

Negociación de los Títulos Valores

Los Derechos de Usufructo sirven para traspasar los derechos económicos, más no los derechos políticos sobre un Título
Valor, constituyendo uno en si mismo, representativo del Contrato. 

La Bolsa Descentralizada de Valores de Venezuela ha creado en Central+ las condiciones para que los Participantes
puedan disfrutar de las tecnologías descentralizadas cumpliendo con todo el rigor de la Ley y la normativa vigente.

A diferencia de otros Títulos Valores, los Derechos de Usufructo pueden negociarse de forma completamente 
descentralizada. El Participante no obstante debe entender los riesgos que esto implica y que vienen expuestos en el 
siguiente Contrato, en especial en materia de Prevención de Delitos de Legitimación de Capitales, Financiamiento al 
Terrorismo, Proliferación de Armas de Destrucción Masiva y otros Ilícitos. 

----------------------------------------------------------------------

Cómo transformar Derechos de Usufructo en Títulos Valores y viceversa

1. Títulos Valores a Derechos de Usufructo: Dirigirse a la plataforma Central+. Opción de Retiro. Seleccionar el 
Título Valor. Seleccionar el wallet de la Blockchain escogida. Ejecutar el Retiro. La ejecución del Retiro
automáticamente firma el contrato del DUs por el Título Valor retirado. 

2. Derechos de Usufructo a Títulos Valores: Dirigirse a la plataforma Central+. Opción de Recarga. Seleccionar el 
Título Valor. Seleccionar el wallet de la Blockchain escogida. Ejecutar la Recarga. La ejecución del Recarga
automáticamente rescinde el contrato del DUs y ejecuta la opción de compra del Título Valor subyacente.

----------------------------------------------------------------------

Ejemplos de cómo generar ingresos con los Derechos de Usufructo 

1. Identifique el precio de los DUs en los mercados alternativos vs Central+.
2. Identifique primero si entre los mercados alternativos hay diferencias de precios. Compre en el más barato, pase
de blockchain a través de Central+ y luego Venda en el más caro, generando una ganancia por arbitraje.
3. Identifique, en el caso de que no haya discrepancia entre los mercados alternativos, si existe discrepancia entre
los mercados alternativos y Central+. Compre en el más barato y venda en el más caro obteniendo una ganancia por
arbitraje. 
4. Dependiendo del subyacente, los DUs tienen diferentes características. Usted puede invertir en los DUs para
aprovechar los derechos económicos del subyacente a largo plazo.
5. En los mercados alternativos, puede también contribuir a pools de liquidez para generar ingresos como market maker.

----------------------------------------------------------------------

CONTRATO DE USUFRUCTO 

Caracas 01 de Julio de 2021
_________________________________________________________________

Entre el NUDO PROPIETARIO especificado en el Anexo A y el Participante inscrito en la BOLSA DESCENTRALIZADA DE 
VALORES DE VENEZUELA, C.A., quien a los efectos del presente contrato se denominará USUFRUCTUARIO, se ha convenido 
celebrar el siguiente contrato de Compra de Derecho de Usufructo el cual será denominado “DUs” bajo los siguientes 
términos: 

1. Definiciones. A los efectos de este contrato, los siguientes términos tendrán las siguientes 
definiciones:

“Usufructo” de conformidad con el artículo 583 del Código Civil de La República Bolivariana de Venezuela, es el 
Derecho Real de usar y gozar temporalmente de las cosas cuya propiedad pertenece a otro, del mismo modo que lo haría 
el propietario. 

“Fecha Valor” del USUFRUCTO, es la fecha en la cual el USUFRUCTUARIO adquiere del NUDO PROPIETARIO el Derecho 
de Usufructo sobre los Valores. 

“Fecha de Vencimiento” del USUFRUCTO, es la fecha en la cual o a partir de la cual se extingue el Derecho de 
Usufructo. 

“Monto de Efectivo” del USUFRUCTO es el monto de efectivo o títulos valores que el NUDO PROPIETARIO recibe del 
USUFRUCTUARIO, por concepto de la adquisición del USUFRUCTO en la Fecha Valor. 

“Valores” significan valores y contratos sobre bienes, productos y servicios permitidos por la Ley especificados 
en el Anexo A.

“Anexo A” contiene los términos, valores, montos y fechas sobre las cuales se realiza la operación de USUFRUCTO.

“DUs” significa una operación de compra del Derecho Real de Usufructo, en virtud del cual el USUFRUCTUARIO adquiere 
del NUDO PROPIETARIO el Derecho de uso y disfrute de los Valores, durante un tiempo definido a cambio de un Monto de
Efectivo.

2. Aceptación.  Cada operación de DUs entre el NUDO PROPIETARIO y el USUFRUCTUARIO será efectiva
y vinculante desde el momento que exista acuerdo entre las partes y el mismo conste de la aceptación 
de las condiciones del contrato mediante su firma digital a través de una de las plataformas transaccionales de 
la BDVE, que puede ser ejecutada por transferencia (si esta es aceptada por el receptor) o pacto. Las condiciones 
y términos de la operación constarán en el Anexo “A” del presente contrato. 

3. Obligaciones en la Fecha Valor.  En la Fecha Valor, el NUDO PROPIETARIO transferirá el Derecho 
Real de Usufructo, contra la recepción del Monto de Efectivo.  

4. Recursos contra el Emisor.  El NUDO PROPIETARIO no garantiza al USUFRUCTUARIO la solvencia del 
emisor sobre los Valores, y por tanto el USUFRUCTUARIO no tendrá ningún recurso ni acción contra el NUDO 
PROPIETARIO, en caso que el emisor dejare de cancelar cualquier cantidad pagadera bajo los Valores.  

Por su parte, el NUDO PROPIETARIO no estará obligado al cobro de cualesquiera pagos que deba efectuar el
emisor de los Valores durante la vigencia del DUs, toda vez que la obligación de reembolso de tales cantidades 
al USUFRUCTUARIO está sujeto a la condición de pago voluntario y oportuno por parte del emisor o deudor de los 
Valores. 

Por otra parte, en ningún caso el NUDO PROPIETARIO será responsable por la disminución en el valor de mercado 
de los Valores durante la vigencia del DUs.

5. Objeto del USUFRUCTO.  Serán objeto de usufructo los Valores que se especifican en el Anexo A. El DUs 
comprenderá los derechos especificados en el Anexo A bajo el título “DERECHOS DEL USUFRUCTUARIO”.

6. Obligaciones en la Fecha de Vencimiento.  En la Fecha de Vencimiento, el DUs quedará extinguido recibiendo
el NUDO PROPIETARIO todos los derechos transferidos en la Fecha Valor. El USUFRUCTUARIO tendrá el derecho a exigir,
dentro de los 05 días siguientes a la Fecha de Vencimiento la compraventa de los Valores en los términos definidos 
en el Anexo A bajo el título “OPCIÓN DE COMPRA DE VALORES”.

7. Momento de Pago a través de los mercados de la BDVE.  El USUFRUCTUARIO deberá ejecutar su prestación dentro de 
las 24 horas siguientes a la ejecución de la voluntad de pacto.

8. Mercado Secundario.  El USUFRUCTUARIO entiende y acepta que el DUs podrá ser libremente transferido en mercados 
descentralizados en la blockchain de Polygon, en la Binance Smart Chain o cualquier otra  blockchain donde se programe 
la desmaterialización de este DUs. El USUFRUCTUARIO es plenamente responsable de la transferencia de sus DUs a cualquier 
persona fuera del control de la Bolsa Descentralizada de Valores de Venezuela, S.A, y de realizar la debida diligencia, 
así como cumplir con toda la normativa en materia de Delitos de Legitimación de Capitales, Financiamiento al Terrorismo, 
Financiamento a la Proliferación de Armas de Destrucción Masiva y otros Ilícitos.

9. Terminación Anticipada.  Si durante el plazo del DUs(i) algún pago de intereses o de dividendos o de 
cualquier otro fruto de los Valores es objeto de alguna retención, cargo o deducción, en virtud de algún cambio 
legislativo o regulatorio; (ii) el emisor de los  Valores notifica de la redención anticipada de los Valores; 
(iii) se anuncia una oferta pública de adquisición, de intercambio o conversión, respecto de los Valores; (iv) 
el emisor otorga a los tenedores de los Valores derechos de suscripción u otros derechos de preferencia no 
transferibles; entonces, salvo que se haya acordado otra cosa, cualquiera de las partes podrá solicitar la 
terminación anticipada del DUs. Dentro de los dos días hábiles siguientes al anuncio de terminación anticipada, 
el USUFRUCTUARIO podrá exigir la compraventa de los Valores en los términos definidos en el Anexo A bajo el título 
“OPCIÓN DE COMPRA DE VALORES”. 

10. Vigencia.  El presente convenio no genera derechos y obligaciones entre las partes sino con motivo de las 
operaciones de DUs que puedan celebrarse de mutuo acuerdo.  Cualquiera de las partes podrá dar por terminado el 
presente contrato.  En todo caso, los derechos y obligaciones bajo el presente contrato continuarán en vigencia 
hasta su liquidación.

11. Ley Aplicable.  El presente contrato estará regulado por lo dispuesto en el Decreto con Rango, Valor y Fuerza
Ley de Mercado de Valores, la normativa prudencial que dicte la Superintendencia Nacional de Valores y por las leyes 
de la República de Venezuela. Las partes objeto del presente contrato, se obligan a cumplir sus obligaciones de buena 
fe y a solucionar mediante negociaciones amigables las posibles disputas, diferencias o controversias que surjan de 
la ejecución del contrato.  De no llegarse a un acuerdo, el cumplimiento de las obligaciones de las partes deberá 
resolverse a través del canal de resolución de conflictos que mantiene la BDVE a tal efecto.


ANEXO A

Para:	Todo Participante que acepte mediante la ejecución de lo descrito en la cláusula 2 del Contrato.
Fecha:	Fecha de pacto o transferencia.

Hacemos referencia a la transferencia del Derecho Real de Usufructo celebrado entre usted(es) y quien suscribe 
en fecha de pacto. Salvo que se especifique lo contrario, los términos que se usen en esta comunicación tendrán el 
significado que se atribuye en el DUs, el cual antecede a la presente confirmación de la siguiente operación:

NUDO PROPIETARIO: Bolsa Descentralizada de Valores de Venezuela, S.A.
USUFRUCTUARIO: Todo Participante que acepte mediante la ejecución de lo descrito en la cláusula 2 del Contrato.
Fecha Valor: 01 de Julio de 2022
Fecha de Vencimiento: Perpétuo
Valores: BDVE
Monto Nominal: [Definir el monto de DUs a emitir]
Símbolo: BDVE
Monto de Efectivo: 1 BDVE en Central+ por cada 100 BDVE en la blockchain de Polygon o Binance SmartChain o cualquiera
a la que se integre en el futuro.

La presente operación de DUs y su liquidación está sujeta a los términos y condiciones del Contrato. 

DERECHOS DEL USUFRUCTUARIO

El USUFRUCTUARIO tendrá los siguientes derechos sobre los valores:
Derecho sobre los dividendos, intereses o distribuciones del Valor subyacente.

OPCIÓN DE COMPRA DE VALORES

El USUFRUCTUARIO podrá ejercitar una opción de compra de los valores subyacentes al DUs en cualquier momento a razón
del Monto de Efectivo, transfiriendo sus DUs a la dirección especificada en Central+ para ello.

*/

/*
ESTRUCTURA DEL TOKEN (REPRESENTACIÓN VIRTUAL DESMATERIALIZADA DEL TÍTULO VALOR)
*/

interface IERC20{
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract ERC20Basic is IERC20{

    string public constant name = "Derechos de Usufructo BDVE";
    string public constant symbol = "BDVE";
    uint8 public constant decimals = 2;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowed;
    uint256 totalSupply_;

    constructor (uint256 initialSupply) public{
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256){
        return totalSupply_;
    }
    
    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256){
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns (uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

     function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}