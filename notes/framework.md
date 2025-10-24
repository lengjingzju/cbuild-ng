# Ten Design Principles for Software Frameworks

---

## Overview

In the world of software engineering, framework design is not merely a technical implementation but an art of balance. An excellent framework is like a city blueprint, providing a solid foundation for current construction while reserving flexibility for future development; it must ensure the independence and efficiency of various functional areas while guaranteeing the harmony and unity of the overall system.

Software frameworks are the cornerstone of a developer's daily work, directly impacting team productivity, code quality, and system maintainability. A well-designed framework can **reduce cognitive load**, allowing developers to focus on business logic rather than technical details; it can **promote code reuse**, avoiding the waste of reinventing the wheel; and it can **ensure system stability** by reducing the risk of changes through good abstraction and isolation.

However, framework design faces eternal challenges: how to strike a balance between **flexibility and simplicity**? How to find the sweet spot between **feature richness** and **ease of use**? How to allow **new technologies** and **legacy systems** to coexist harmoniously? The answers to these questions lie in design principles validated by countless projects.

The ten design principles distilled in this article originate from the practical wisdom of the industry. They are not rigid dogmas but time-tested guiding principles. From understanding the timing of code refactoring to the division of system architecture layers; from considerations of ecosystem compatibility to the pacing of performance optimization – these principles will help you build software frameworks that are both robust and elegantly flexible.

Whether you are designing a new framework from scratch or optimizing an existing system architecture, these principles will provide clear guidance, helping you find the optimal path through the complex maze of technology and create software infrastructure that stands the test of time.

## Principle 1: The Rule of Three

**"Three strikes and you refactor"**

### Core Idea

When the same code pattern appears in three different places, it's time to abstract and refactor.

### Detailed Explanation

This is not a mechanical counting rule but an important decision trigger. The first implementation might be accidental, the second repetition might still be exploratory, but the third occurrence clearly indicates a common pattern that requires abstraction.

**Analogy:**

> Just like in urban planning, when spontaneous small commodity markets form in three different neighborhoods, the city government should consider building a centralized commercial center. This avoids duplicate construction while providing more professional facilities and services.

### Practical Guidance

- First implementation: Focus on solving the problem
- Second repetition: Start documenting the pattern
- Third occurrence: Refactor immediately

## Principle 2: Ecosystem Compatibility Principle

**"Honor the past, be compatible with the present, embrace the future"**

### Core Idea

New frameworks must respect and be compatible with existing ecosystems, providing smooth migration paths to make change easier for users to accept.

### Detailed Explanation

The biggest resistance to technological change is often not the technology itself, but migration costs and ecosystem fragmentation. Excellent frameworks should evolve like biological systems - innovative yet maintaining continuity.

**Urban Planning Analogy:**

> Modern urban renewal doesn't start from scratch but optimizes based on the original road grid. London's subway system continuously upgrades while maintaining century-old lines, with old and new systems coexisting harmoniously.

### Implementation Strategies

- **Gradual Migration**: Provide adapter patterns for legacy code to migrate progressively
- **Dual-track Operation**: Allow old and new systems to run in parallel to reduce risk
- **Compatibility Layer Design**: Provide wrapper layers for existing interfaces to maintain backward compatibility
- **Toolchain Support**: Offer automated migration tools to reduce manual effort

## Principle 3: Intermediate Layer Isolation Principle

**"Intermediate layers are buffers for change, keeping the top layer stable as a rock"**

### Core Idea

Isolate top-level applications from direct dependencies on underlying implementations through intermediate abstraction layers, supporting multiple underlying implementations without modifying upper-level code.

### Detailed Explanation

Intermediate layers are like diplomats, translating and coordinating between different systems, allowing each party to focus on their own domain without understanding the other's details.

**Computer Architecture Analogy:**

> The operating system is a typical intermediate layer - applications don't need to care about specific hardware, just call system APIs; hardware manufacturers only need to provide standard drivers without adapting to each application.

### Design Points

- **Unified Interface Definition**: Intermediate layers provide stable abstract interfaces
- **Multiple Implementation Support**: Same interface can have multiple underlying implementations
- **Transparent Switching**: Underlying switching is completely transparent to upper layers
- **Dependency Inversion**: Upper layers depend on abstract interfaces, not concrete implementations

## Principle 4: Layered Architecture Principle

**"Mechanisms at the bottom, abstractions in the middle, policies at the top"**

### Core Idea

Different layers focus on different design goals: the bottom layer provides basic capabilities, the middle layer establishes abstract models, and the top layer optimizes user experience.

### Detailed Explanation

**Bottom Mechanism Layer**:

- Focus on performance, stability, and scalability
- Provide raw basic capabilities
- Like computer hardware layer, providing basic computing, storage, and networking capabilities

**Middle Abstraction Layer**:

- Establish unified domain models
- Encapsulate complex technical details
- Like operating system kernel, managing resources and providing system calls

**Top Policy Layer**:

- Focus on usability and development efficiency
- Provide out-of-the-box solutions
- Like graphical user interfaces, allowing average users to use easily

**Automotive Manufacturing Metaphor:**

> Engine and chassis design pursue ultimate performance and reliability (mechanisms), transmission systems establish standard power transmission models (abstractions), while steering wheels and pedals provide intuitive operation methods (policies).

### Practical Points

- Define clear responsibility boundaries for each layer
- Lower layers serve upper layers, upper layers don't depend on lower layer implementation details
- Maintain stable and clear interfaces between layers

## Principle 5: Single Responsibility Principle

**"One module, one clear reason to change"**

### Core Idea

Each module or class should have only one clear responsibility, only one reason that causes it to change.

### Detailed Explanation

When a module takes on too many responsibilities, it becomes fragile and difficult to maintain. Any change in related requirements will affect this module, causing chain reactions.

**Life Metaphor:**

> While Swiss Army knives are versatile, in professional scenarios, people prefer specialized tools. Chefs don't use Swiss Army knives for chopping, carpenters don't use them for sawing. Software modules should similarly be "professional" rather than "all-purpose."

### Practical Points

- Responsibilities should be cohesive and functionally related
- Reasons for change should be single and clear
- Interfaces should remain concise and focused

## Principle 6: Moderate Abstraction Principle

**"Abstract sufficiently, but don't overdo it"**

### Core Idea

Find the balance point between concrete implementation and over-abstraction; abstraction should be based on real needs rather than imagination.

### Detailed Explanation

Over-abstraction is a common design trap. It increases system complexity without necessarily bringing practical value.

**Warning Signs of Over-abstraction:**

- More abstraction layers than actually needed
- "Might need in the future" features never get used
- Configuration becomes more complex than coding
- Simple modifications require multi-layer propagation

**Architecture Analogy:**

> When building a house, we reserve wire conduits (moderate abstraction), but we don't pre-install all possible appliances for every room (over-abstraction). Good design provides possibilities for extension without imposing unverified requirements.

### Practical Suggestions

- Base abstraction on at least three real use cases
- Delay abstraction until truly needed
- Maintain understandability of abstractions

## Principle 7: Pareto Principle Application

**"Satisfy 80% of core needs, reserve 20% for extension space"**

### Core Idea

Focus on solving common needs for most users, provide extension mechanisms for special needs, but don't build them in.

### Detailed Explanation

Trying to satisfy 100% of needs often makes the system overly complex,反而 affecting the core user experience.

**Business Wisdom:**

> Successful restaurants typically have clear signature dishes (satisfying 80% of customers' core needs), while accepting special orders (providing possibilities for 20% of special needs). Restaurants trying to make menus satisfy everyone's tastes often lose their distinctive features.

### Implementation Strategies

- Identify core usage scenarios
- Provide elegant implementations for core paths
- Provide extension points for edge scenarios
- Clearly define the framework's capability boundaries

## Principle 8: Interface Stability Principle

**"Interfaces are promises, implementations are details"**

### Core Idea

Provide stable interfaces externally, while internal implementations can change flexibly.

### Detailed Explanation

Interfaces are contracts between modules; frequent changes make systems fragile. However, optimization and improvement of internal implementations should be encouraged.

**Electronics Analogy:**

> Power outlet standards remain unchanged for decades (stable interfaces), but power plant technologies continuously upgrade (internal implementations). Users enjoy better electricity services without needing to replace electrical appliances.

### Maintenance Strategies

- Design interfaces thoughtfully
- Maintain backward compatibility in minor versions
- Provide clear migration paths for major versions
- Give transition periods for deprecated interfaces

## Principle 9: Data Flow Priority

**"Design data flow first, then implement processing logic"**

### Core Idea

The core of framework design is understanding how data flows; modules are merely processing stations for data.

### Detailed Explanation

Many design problems stem from insufficient understanding of data flow. Clarify data sources, transformations, and destinations, and module partitioning becomes naturally clear.

**Transportation System Metaphor:**

> Urban planners first design road networks (data flow), then plan commercial, residential, and industrial areas (processing modules). Poor transportation planning makes even the best buildings difficult to utilize effectively.

### Design Steps

1. Identify data sources and data consumers
2. Design data transformation pipelines
3. Determine data storage and caching strategies
4. Plan error handling and data recovery

## Principle 10: Progressive Optimization Principle

**"First make it right, then make it clear, finally make it fast"**

### Core Idea

Optimization should be progressive and data-driven, not premature and based on speculation.

### Detailed Explanation

Premature optimization is the root of all evil. Pursuing performance optimization before ensuring correctness and clarity often backfires.

**Manufacturing Analogy:**

> Automobile manufacturers first ensure vehicle safety and reliability (correctness), then improve driving experience (clarity), and finally optimize fuel efficiency through wind tunnel experiments (performance optimization). Reversing this order leads to disastrous consequences.

### Optimization Path

1. **Functional Correctness**: Ensure logical correctness and accurate results
2. **Code Clarity**: Guarantee readability for maintainability
3. **Reasonable Architecture**: Design good module relationships and interfaces
4. **Performance Optimization**: Conduct targeted optimization based on actual performance data

## In-depth Practice of Layered Architecture

### Bottom Mechanism Design Points

- **Purity**: Provide basic capabilities without business logic
- **Testability**: Each mechanism can be tested independently
- **Documentation**: Clearly specify capability boundaries and usage constraints

### Middle Abstraction Design Points

- **Domain Modeling**: Accurately reflect business concepts and relationships
- **Interface Design**: Provide clear, consistent access methods
- **Error Handling**: Define unified exception and error code systems

### Top Policy Design Points

- **User Experience**: Focus on developers' usage experience
- **Default Configuration**: Provide reasonable defaults for common scenarios
- **Learning Curve**: Control complexity to make onboarding easy for newcomers

## Principle Application: Avoiding Common Pitfalls

### Pitfall 1: Over-engineering

**Symptoms**:

- Designing complex abstractions for "possible" requirements
- Configuration becomes more complex than usage
- Simple tasks require multi-layer calls

**Antidote**:

Follow the YAGNI principle (You Ain't Gonna Need It) - you really don't need it until you really need it.

### Pitfall 2: Insufficient Abstraction

**Symptoms**:

- Lots of duplicate code
- Changes affect everything
- New feature development requires copy-paste

**Antidote**:

Apply the Rule of Three to promptly identify and abstract repeating patterns.

### Pitfall 3: Perfectionism Trap

**Symptoms**:

- Constant refactoring, never able to release
- Over-designing for edge cases
- Pursuing theoretical perfection over practical value

**Antidote**:

Remember "done is better than perfect," adopt iterative development.

### Pitfall 4: Ecosystem Fragmentation

**Symptoms**:

- New framework incompatible with existing toolchains
- Excessive migration costs, user resistance to change
- Ecosystem fragmentation, community split

**Antidote**:

Follow the Ecosystem Compatibility Principle, provide smooth migration paths and compatibility layers.

### Pitfall 5: Layer Confusion

**Symptoms**:

- Business logic leaking into bottom mechanisms
- Technical details polluting top-level interfaces
- Unclear responsibilities between layers, mutual dependencies

**Antidote**:

Define clear layer boundaries, insist on dependency direction from top to bottom.

## Design Decision Framework

When facing design choices, ask yourself these questions:

### Refactoring Decision Checklist

- [ ] Does this pattern appear in more than three places?
- [ ] Does modifying functionality require making the same changes in multiple places?
- [ ] Does new feature development require copying existing code?

### Abstraction Level Checklist

- [ ] Is this abstraction based on real needs or imagination?
- [ ] Does the abstraction make core use cases simpler?
- [ ] Can new team members understand this design within one day?

### Ecosystem Compatibility Checklist

- [ ] Is the new design compatible with existing workflows?
- [ ] Is the migration path clear and feasible?
- [ ] Is the user learning cost controllable?
- [ ] Is a rollback mechanism provided?

### Layered Design Checklist

- [ ] Are responsibilities clear for each layer?
- [ ] Do lower layers provide necessary support for upper layers?
- [ ] Are dependency relationships between layers reasonable?
- [ ] Can change impacts be isolated within a single layer?

### Intermediate Layer Design Checklist

- [ ] Are top-level applications decoupled from underlying implementations?
- [ ] Does it support multiple underlying implementations?
- [ ] Does underlying switching affect upper layers?
- [ ] Are intermediate layer interfaces stable and concise?

## Conclusion: Pragmatic Design Wisdom

Excellent framework design doesn't pursue theoretical perfection but finds the best balance under various constraints. It requires:

**Technical Judgment**: Knowing what technologies suit which problems
**Business Understanding**: Clearly understanding the core problems to solve
**User Empathy**: Understanding the difficulties and needs of framework users
**Practical Wisdom**: Finding feasible paths between ideal and reality
**Ecosystem Thinking**: Respecting existing investments, providing smooth evolution
**Layered Thinking**: Solving different problems at different abstraction levels

Remember: The best framework is one that elegantly solves practical problems while making developers feel delighted. It shouldn't be a complex system that requires constant fighting against, but an amplifier that magnifies developers' capabilities.

**Final Validation Criteria**:

> When new members can understand and use your framework within reasonable time, when common needs can be elegantly solved, when special needs have clear extension paths, when existing users are willing to migrate smoothly - your framework design has reached excellence.

**Ultimate Value of Layered Architecture**:

> Through clear layer division, we make complex systems understandable; through stable interface agreements, we make team collaboration efficient; through appropriate abstraction design, we make technological evolution smooth. This is not just the art of software design, but the wisdom of engineering management.
