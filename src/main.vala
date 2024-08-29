public class Musys.Main {
    public Vala.CodeContext src_context;
    public Vala.SourceFile  src;

    public static string output_filename = null;
    public static int    optimize_level  = 0;
    public static OptionEntry[] options = {
        {"out", 'o', 0, OptionArg.FILENAME, ref output_filename, "Target program filename", "TARGET"},
        {"opt", 'O', 0, OptionArg.INT,      ref optimize_level,  "Optimization Level",      "LEVEL"},
    };
    public static int main(string []args)
    {
        return 0;
    }
}