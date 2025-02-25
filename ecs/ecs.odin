package ecs;

/*

The entity type of an unsigned 64 bit integer

*/
Entity :: distinct u64


/*

Stores the type id and rawptr to the data for the component

*/
ComponentStorage :: struct 
{
    type_id:     typeid,
    data:        rawptr,
    delete_proc: proc(data: rawptr)
}

/*

Where the information for the entity and components are stored

*/
World :: struct 
{
    counter:    u64,
    entities:   [dynamic]Entity,
    components: map[typeid]ComponentStorage,
}

/*

Initializes a world struct and returns it

*/
init_world := proc() -> World
{
    return World {
        entities = make([dynamic]Entity),
        components = make(map[typeid]ComponentStorage)
    }
}

/*

Called near the end of the world's lifespan to loop over and delete the entities and components

*/
destroy_world := proc(world: ^World)
{
    delete(world.entities)

    for _, storage in world.components
    {
        storage.delete_proc(storage.data)
    }

    delete(world.components)
}

/*

Creates an entity with a counter that can never be reset

*/
create_entity :: proc(world: ^World) -> Entity
{
    world.counter += 1
    entity := Entity(world.counter)
    append(&world.entities, entity)
    return entity
}

/*

Destroy an entity and its associated components

*/
destroy_entity :: proc(world: ^World, entity: Entity) {
    // removes the components attached to the entity
    for _, storage in world.components {
        m := cast(^map[Entity]rawptr)storage.data
        if entity in m^ {
            // delete(m, entity)
        }
    }

    // Remove the entity from the world
    for i, e in world.entities {
        if world.entities[i] == entity {
            ordered_remove(&world.entities, i)
            break
        }
    }
}

/*

Add a component to an entity

*/
add_component :: proc(world: ^World, entity: Entity, component: rawptr, component_type: typeid) {
    if component_type not_in world.components {
        m := new(map[Entity]rawptr)
        m^ = make(map[Entity]rawptr)
        delete_proc :: proc(data: rawptr) {
            m := cast(^map[Entity]rawptr)data
            delete(m^)
            free(m)
        } 
        world.components[component_type] = ComponentStorage {
            type_id =     component_type,
            data =        m,
            delete_proc = delete_proc,
        }
    }
    storage := &world.components[component_type]
    m := cast(^map[Entity]rawptr)storage.data
    m^[entity] = component
}

/*

Remove a component from an entity

*/
remove_component :: proc(world: ^World, entity: Entity, component_type: typeid) {
    if component_type in world.components {
        storage := world.components[component_type]
        m := cast(^map[Entity]rawptr)storage.data
        if entity in m^ {
            delete(m^)
        }
    }
}

/*

Retrieve a component from an entity

*/
get_component :: proc(world: ^World, entity: Entity, component_type: typeid) -> rawptr {
    if component_type in world.components {
        storage := world.components[component_type]
        m := cast(^map[Entity]rawptr)storage.data
        return m^[entity]
    }
    return nil
}
