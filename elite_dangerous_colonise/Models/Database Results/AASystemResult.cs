namespace elite_dangerous_colonise.Models.Database_Results
{
    public class AASystemResult
    {
        public string Name { get; set; }
        public decimal X { get; set; }
        public decimal Y { get; set; }
        public decimal Z { get; set; }

        public AASystemResult(string name, decimal x, decimal y, decimal z)
        {
            Name = name;
            X = x;
            Y = y;
            Z = z;
        }
    }
}
