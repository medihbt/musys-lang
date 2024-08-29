using Vala;

public errordomain Musys.IRGen.ExprGenErr {
    EVAL_NON_CONSTEXPR;
}

public class Musys.IRGen.ExprGenerator: Vala.CodeVisitor {
    public unowned Generator parent{get;set;}
    public bool              consteval_mode;

    public IR.Value generate(Vala.Expression expr) throws ExprGenErr, RuntimeErr {
        assert_not_reached();
    }
}