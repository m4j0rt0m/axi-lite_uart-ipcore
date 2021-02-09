load_package flow

proc make_all_pins_virtual {args} {

    execute_module -tool map

    set name_ids [get_names -filter * -node_type pin]
    set clk_ids {}
    foreach clk_id [lrange $args 0 end] {
        lappend clk_ids $clk_id
    }

    foreach_in_collection name_id $name_ids {
        set pin_name [get_name_info -info full_path $name_id]
        if { -1 == [lsearch -exact $clk_ids $pin_name] } {
            post_message "Making VIRTUAL_PIN assignment to $pin_name"
            set_instance_assignment -to $pin_name -name VIRTUAL_PIN ON
        } else {
            post_message "Skipping VIRTUAL_PIN assignment to $pin_name"
        }
    }

    export_assignments
}
