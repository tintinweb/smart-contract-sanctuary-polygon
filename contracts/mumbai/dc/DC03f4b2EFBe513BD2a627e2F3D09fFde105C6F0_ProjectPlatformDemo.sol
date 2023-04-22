// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Sistema de gestión descentralizado de la financiación de proyectos.
 * @author Elvi Mihai Sabau Sabau, aka: Frenzoid => github.com/frenzoid.
 * @notice Este contrato implementa una plataforma de financiamiento colectiva y autónoma,
 * donde los usuarios pueden proponer nuevos proyectos, y la comunidad se encarga de gestionar
 * la recaudación, integridad y viabilidad de dichos proyectos mediante votos.
 */
contract ProjectPlatformDemo {
    /// @dev Enumeración para representar el estado de un proyecto.
    enum ProjectState {
        PENDING,
        FUNDING,
        FUNDED,
        CANCELLED
    }

    /// @dev Estructura para representar un comentario.
    struct Comment {
        address author; // Dirección del autor del comentario.
        string message; // Texto del comentario.
        uint date; // Fecha del comentario.
    }

    /// @dev Estructura para representar una inversion.
    struct Investment {
        address investor; // Dirección del inversor.
        uint amount; // Cantidad invertida.
        uint date; // Fecha de la inversión.
    }

    /// @dev Estructura para representar un proyecto.
    struct Project {
        address proposer; // Dirección del proponente del proyecto.
        string title; // Título del proyecto.
        string description; // Descripción del proyecto.
        uint requiredFunds; // Fondos necesarios para el proyecto.
        uint collectedFunds; // Fondos recaudados.
        uint totalDevelopmentTime; // Tiempo total de desarrollo del proyecto.
        uint deadline; // Fecha límite para la siguiente fase (votación, financiación o validación de hitos).
        uint totalVotes; // Total de votos recibidos.
        uint positiveVotes; // Total de votos positivos recibidos.
        ProjectState state; // Estado del proyecto (pendiente, aprobado, financiado o cancelado).
        Investment[] investments; // Array para controlar las inversiones de cada dirección en el proyecto.
        Comment[] comments; // Array para almacenar los comentarios del proyecto.
        mapping(address => bool) hasVoted; // Mapping para controlar quién ha votado el proyecto.
    }

    /// @dev Tiempo límite para la votación y financiación en segundos (30 días)
    uint private constant TIME_LIMIT = 30 days;

    /// @dev Umbral de Votación. Porcentaje mínimo de votos positivos para aprobar un proyecto.
    uint private constant APPROVAL_THRESHOLD = 85;

    /// @dev Lista de proyectos
    Project[] public projects;

    /// @dev Eventos para registrar las acciones realizadas en el contrato.
    event ProjectProposed(uint indexed projectId, address indexed proposer);
    event ProjectApproved(uint indexed projectId);
    event ProjectRejected(uint indexed projectId);
    event ProjectInvested(
        uint indexed projectId,
        address indexed investor,
        uint amount
    );
    event ProjectFunded(uint indexed projectId);
    event ProjectCancelled(uint indexed projectId);
    event ProjectInvestmentWithdrawn(
        uint indexed projectId,
        address indexed investor,
        uint amount
    );
    event CommentAdded(
        uint indexed projectId,
        address indexed commenter,
        string message
    );

    /// @dev Constructor del contrato, se ejecuta una sola vez al desplegar el contrato.
    constructor() {
        /**
         * @dev Creamos 4 proyectos de ejemplo,
         * uno con el estado PENDING, otro con el estado FUNDING,
         * otro con el estado FUNDED, y el ultimo con el estado CANCELLED.
         *
         * Usamos la funcion proposeProject para crear los proyectos,
         */
        proposeProject(
            "Salon de tuneo",
            "En mi garaje de tuneo de coches personalizamos y mejoramos motores, suspensiones, frenos y carrocerias de vehiculos para hacerlos unicos y mas potentes. Tambien ofrecemos servicios de mantenimiento completo para mantener los autos en optimas condiciones.",
            3,
            30
        );
        proposeProject(
            "Panaderia",
            "Mi panaderia es un lugar donde puedes encontrar panes recien horneados, pasteles, galletas y empanadas para disfrutar en cualquier momento del dia. Ofrecemos productos de alta calidad, preparados con ingredientes frescos y con la pasion de una panaderia artesanal.",
            2,
            30
        );
        proposeProject(
            "Evento contra el cancer",
            "Mi evento benefico contra el cancer reune fondos para la investigacion y tratamiento de esta enfermedad. Ofrecemos entretenimiento, subasta de obras de arte y productos locales. ",
            10,
            30
        );
        proposeProject(
            "Mi Lamborghini",
            "Mi Lamborghini es un auto deportivo de lujo. Ofrece un alto rendimiento, velocidad y estilo. Es un icono de la ingenieria italiana y una experiencia de manejo emocionante y exclusiva.",
            100000,
            30
        );

        /**
         * @dev Cambiamos el estado del proyecto 1 a FUNDING.
         */
        projects[0].state = ProjectState.FUNDING;

        /**
         * @dev Cambiamos el estado del proyecto 2 a FUNDING.
         */
        projects[1].state = ProjectState.FUNDING;

        /**
         * @dev Cambiamos el estado del proyecto 3 a FUNDED.
         */
        projects[2].state = ProjectState.FUNDED;

        /**
         * @dev Cambiamos el estado del proyecto 4 a CANCELLED.
         */
        projects[3].state = ProjectState.CANCELLED;

        /**
         * @dev Añadimos comentarios a los proyectos.
         */
        addComment(0, "Comentario 1");
        addComment(0, "Comentario 2");
        addComment(1, "Comentario 1");
        addComment(1, "Comentario 3");
        addComment(2, "Comentario 1");
        addComment(2, "Comentario 3");
        addComment(3, "Comentario 1");
        addComment(3, "Comentario 3");
    }

    /**
     * RF5
     * @notice Devuelte el total de proyectos.
     * @return uint256
     */
    function getProjectsCount() public view returns (uint256) {
        return projects.length;
    }

    /**
     * RF4
     * @notice Propone un nuevo proyecto para ser aprobado por la comunidad.
     * @param _title Título del proyecto
     * @param _description Descripción del proyecto
     * @param _fundingGoal Cantidad de fondos ( en Ether ) necesarios para su formalización
     * @param _totalDevelopmentTime Tiempo total (días) para su desarrollo
     * @return ID del proyecto
     */
    function proposeProject(
        string memory _title,
        string memory _description,
        uint _fundingGoal,
        uint _totalDevelopmentTime
    ) public returns (uint256) {
        /// @dev Validaciones de los parámetros de entrada
        require(bytes(_title).length > 0, "El titulo no puede estar vacio");
        require(
            bytes(_description).length > 0,
            "La descripcion no puede estar vacia"
        );
        require(
            _fundingGoal > 0,
            "El objetivo de financiacion debe ser mayor que 0"
        );
        require(
            _totalDevelopmentTime > 0,
            "El tiempo total de financiacion debe ser mayor que 0"
        );

        /// @dev Creación del nuevo proyecto
        Project storage newProject = projects.push();

        newProject.proposer = msg.sender;
        newProject.title = _title;
        newProject.description = _description;
        newProject.requiredFunds = _fundingGoal * 1 ether;
        newProject.totalDevelopmentTime = (_totalDevelopmentTime * 1 days);
        newProject.deadline = block.timestamp + TIME_LIMIT;
        newProject.state = ProjectState.PENDING;

        // Emitimos el evento ProjectProposed
        emit ProjectProposed(projects.length - 1, msg.sender);

        return projects.length - 1;
    }

    /**
     * RF5
     * @notice Devuelve un proyecto dado un ID
     * @param _projectId ID del proyecto
     * @return proposer Dirección del creador del proyecto
     * @return title Título del proyecto
     * @return description Descripción del proyecto
     * @return requiredFunds Fondos requeridos para el proyecto
     * @return collectedFunds Fondos recaudados para el proyecto
     * @return totalDevelopmentTime Tiempo total de desarrollo del proyecto
     * @return deadline Fecha límite del proyecto
     * @return totalVotes Votos totales del proyecto
     * @return positiveVotes Votos positivos del proyecto
     * @return userVoted Booleano que indica si el usuario ha votado el proyecto
     * @return state Estado del proyecto
     */
    function getProject(
        uint256 _projectId
    )
        public
        view
        returns (
            address proposer,
            string memory title,
            string memory description,
            uint requiredFunds,
            uint collectedFunds,
            uint totalDevelopmentTime,
            uint deadline,
            uint totalVotes,
            uint positiveVotes,
            bool userVoted,
            ProjectState state
        )
    {
        require(_projectId < projects.length, "El proyecto no existe");

        Project storage project = projects[_projectId];

        proposer = project.proposer;
        title = project.title;
        description = project.description;
        requiredFunds = project.requiredFunds;
        collectedFunds = project.collectedFunds;
        totalDevelopmentTime = project.totalDevelopmentTime;
        deadline = project.deadline;
        totalVotes = project.totalVotes;
        positiveVotes = project.positiveVotes;
        userVoted = hasVoted(_projectId, msg.sender);
        state = project.state;
    }

    /**
     * RF7
     * @notice Devuelve la cantidad de comentarios de un proyecto dado un ID.
     * @param _projectId ID del proyecto
     * @return uint256
     */
    function getCommentsCount(
        uint256 _projectId
    ) public view returns (uint256) {
        require(_projectId < projects.length, "El proyecto no existe");
        return projects[_projectId].comments.length;
    }

    /**
     * RF6
     * @notice Añade un comentario a un proyecto.
     * @param _projectId ID del proyecto
     * @param _comment Comentario a añadir
     */
    function addComment(uint256 _projectId, string memory _comment) public {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            bytes(_comment).length > 0,
            "El comentario no puede estar vacio"
        );

        /// @dev Añadimos el comentario al proyecto
        Comment storage c = projects[_projectId].comments.push();
        c.author = msg.sender;
        c.message = _comment;
        c.date = block.timestamp;

        // Emitimos el evento CommentAdded
        emit CommentAdded(_projectId, msg.sender, _comment);
    }

    /**
     * RF7
     * @notice Devuelve un comentario dado un ID de proyecto y un ID de comentario
     * @param _projectId ID del proyecto
     * @param _commentId ID del comentario
     * @return author Dirección del autor del comentario
     * @return message Mensaje del comentario
     * @return date Fecha del comentario
     */
    function getComment(
        uint256 _projectId,
        uint256 _commentId
    ) public view returns (address author, string memory message, uint date) {
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            _commentId < projects[_projectId].comments.length,
            "El comentario no existe"
        );

        Comment storage comment = projects[_projectId].comments[_commentId];

        author = comment.author;
        message = comment.message;
        date = comment.date;
    }

    /**
     * @notice Devuelve todos los comentarios de un proyecto
     * @param _projectId ID del proyecto
     * @return comments Array de comentarios
     */
    function getComments(
        uint256 _projectId
    ) public view returns (Comment[] memory comments) {
        require(_projectId < projects.length, "El proyecto no existe");
        return projects[_projectId].comments;
    }

    /**
     * RF8
     * @notice Permite a los usuarios votar por un proyecto.
     * @param _projectId ID del proyecto a votar
     * @param _positiveVote Si el voto es positivo (true) o negativo (false)
     */
    function voteProject(uint256 _projectId, bool _positiveVote) public {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            projects[_projectId].state == ProjectState.PENDING,
            "El proyecto no esta pendiente de aprobacion"
        );
        require(
            block.timestamp < projects[_projectId].deadline,
            "El plazo para votar ha expirado"
        );
        require(
            !projects[_projectId].hasVoted[msg.sender],
            "Ya has votado este proyecto"
        );

        /// @dev Actualizamos los votos del proyecto
        projects[_projectId].totalVotes++;
        if (_positiveVote) projects[_projectId].positiveVotes++;

        /// @dev Marcamos al usuario como que ha votado el proyecto
        projects[_projectId].hasVoted[msg.sender] = true;
    }

    /**
     * RF8
     * @notice Devuelve si el usuario ha votado un proyecto.
     * @param _projectId ID del proyecto
     * @param _user Dirección del usuario a comprobar
     * @return boolean
     */
    function hasVoted(
        uint256 _projectId,
        address _user
    ) public view returns (bool) {
        require(_projectId < projects.length, "El proyecto no existe");
        return projects[_projectId].hasVoted[_user];
    }

    /**
     * RF9
     * @notice Comprueba si un proyecto ha sido aprobado por la comunidad.
     * @param _projectId ID del proyecto a comprobar
     */
    function checkProjectApproval(uint256 _projectId) public {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            projects[_projectId].proposer == msg.sender,
            "No eres el autor"
        );
        require(
            projects[_projectId].state == ProjectState.PENDING,
            "El proyecto no esta pendiente de aprobacion"
        );
        require(
            block.timestamp >= projects[_projectId].deadline,
            "El plazo para votar no ha expirado"
        );

        /// @dev Calculamos el porcentaje de votos positivos
        uint256 positiveVotesPercentage = (projects[_projectId].positiveVotes *
            100) / projects[_projectId].totalVotes;

        /// @dev Actualizamos el estado del proyecto
        if (positiveVotesPercentage >= APPROVAL_THRESHOLD) {
            projects[_projectId].state = ProjectState.FUNDING;

            /// @dev Reiniciamos el plazo para la siguiente fase
            projects[_projectId].deadline = block.timestamp + TIME_LIMIT;

            emit ProjectApproved(_projectId);
        } else {
            projects[_projectId].state = ProjectState.CANCELLED;
            emit ProjectRejected(_projectId);
        }
    }

    /**
     * RF10
     * @notice Permite a los usuarios invertir en un proyecto.
     * @param _projectId ID del proyecto a invertir
     */
    function investInProject(uint256 _projectId) public payable {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            projects[_projectId].state == ProjectState.FUNDING,
            "El proyecto no esta en fase de financiacion"
        );
        require(
            block.timestamp < projects[_projectId].deadline,
            "El plazo para invertir ha expirado"
        );
        require(msg.value > 0, "La cantidad de inversion debe ser mayor que 0");

        /// @dev Actualizamos los fondos recaudados del proyecto
        projects[_projectId].collectedFunds += msg.value;

        /// @dev Creamos un nuevo registro de inversión para el proyecto
        Investment storage newInvestment = projects[_projectId]
            .investments
            .push();
        newInvestment.investor = msg.sender;
        newInvestment.amount = msg.value;
        newInvestment.date = block.timestamp;

        /// @dev Emitimos el evento ProjectInvested
        emit ProjectInvested(_projectId, msg.sender, msg.value);

        /// @dev Si se ha alcanzado el umbral, actualizamos el estado del proyecto
        if (
            projects[_projectId].collectedFunds >=
            projects[_projectId].requiredFunds
        ) {
            projects[_projectId].state = ProjectState.FUNDED;

            /// @dev Enviamos los fondos al autor del proyecto
            address payable wallet = payable(projects[_projectId].proposer);
            wallet.transfer(projects[_projectId].collectedFunds);

            /// @dev Emitimos el evento para que quede registrado
            emit ProjectFunded(_projectId);
        }
    }

    /**
     * RF10
     * @notice Comprueba si un proyecto ha sido financiado.
     * @param _projectId ID del proyecto a comprobar
     */
    function checkProjectFunding(uint256 _projectId) public {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");
        require(
            projects[_projectId].proposer == msg.sender,
            "No eres el autor"
        );
        require(
            projects[_projectId].state == ProjectState.FUNDING,
            "El proyecto no esta en fase de financiacion"
        );
        require(
            block.timestamp >= projects[_projectId].deadline,
            "El plazo para invertir no ha expirado"
        );

        /// @dev Actualizamos el estado del proyecto
        if (
            projects[_projectId].collectedFunds >=
            projects[_projectId].requiredFunds
        ) {
            projects[_projectId].state = ProjectState.FUNDED;

            /// @dev Enviamos los fondos al autor del proyecto
            address payable wallet = payable(projects[_projectId].proposer);
            wallet.transfer(projects[_projectId].collectedFunds);

            /// @dev Emitimos el evento para que quede registrado
            emit ProjectFunded(_projectId);
        } else {
            /// @dev Actualizamos el estado del proyecto, ya que no se ha logrado financiar.
            projects[_projectId].state = ProjectState.CANCELLED;

            /// @dev Emitimos el evento para que quede registrado
            emit ProjectCancelled(_projectId);
        }
    }

    /**
     * RF11
     * @notice Permite a los inversores retirar sus fondos si el proyecto se ha cancelado.
     * @param _projectId ID del proyecto a comprobar.
     */
    function withdrawInvestment(uint256 _projectId) public {
        /// @dev Validaciones de los parámetros de entrada
        require(_projectId < projects.length, "El proyecto no existe");

        /// @dev Si el proyecto aún está en fase de financiación, lanzamos un error.
        require(
            projects[_projectId].deadline < block.timestamp,
            "El proyecto aun esta en fase de financiacion."
        );

        /// @dev Recorremos los registros de inversión del proyecto
        for (uint256 i = 0; i < projects[_projectId].investments.length; i++) {
            /// @dev Si el inversor coincide con el que llama a la función
            if (
                projects[_projectId].investments[i].investor == msg.sender &&
                projects[_projectId].investments[i].amount != 0
            ) {
                /// @dev Actualizamos el registro de inversión
                projects[_projectId].investments[i].amount = 0;

                /// @dev Enviamos los fondos que ha invertido en el proyecto al inversor
                address payable wallet = payable(msg.sender);
                wallet.transfer(projects[_projectId].investments[i].amount);

                /// @dev Emitimos el evento para que quede registrado
                emit ProjectInvestmentWithdrawn(
                    _projectId,
                    msg.sender,
                    projects[_projectId].investments[i].amount
                );
                break;
            }
        }

        /// @dev Si no se ha encontrado el inversor, lanzamos un error.
        require(false, "No has participado en el proyecto.");
    }

    /**
     * @notice funciones de fallback
     * @dev Funciones que se ejecutan cuando se llaman a funciones inexistentes del contrato,
     * o se manda ether al contrato directamente.
     */
    fallback() external payable {
        revert("No se aceptan fondos en la direccion del contrato");
    }

    receive() external payable {
        revert("No se aceptan fondos en la direccion del contrato");
    }
}