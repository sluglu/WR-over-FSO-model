% Helper function for backward compatibility
function val = getfield_default(struct, field, default)
    if isfield(struct, field)
        val = struct.(field);
    else
        val = default;
    end
end