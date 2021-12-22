export function toTitleCase(input: string): string {
    return input.replace(
        /\w\S*/g,
        function(txt) {
          return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
        }
      );
}

export function booleanLabels(input: string, labels?: ['Yes', 'No']): string {
    return input ? "Yes" : "No";
}